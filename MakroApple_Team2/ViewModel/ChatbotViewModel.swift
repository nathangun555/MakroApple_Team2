//
//  ChatbotViewModel.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 21/11/25.
//

import Foundation
import Supabase
import Combine

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }
    let id = UUID()
    let role: Role
    let text: String
    let createdAt: Date = Date()
}

@MainActor
final class ChatBotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isSending: Bool = false
    @Published var errorMessage: String?
    
    // ✅ NEW: Clear conversation
    func clearConversation() {
        messages.removeAll()
        errorMessage = nil
    }
    
    func sendMessage(userId: String) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        
        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        inputText = ""
        isSending = true
        errorMessage = nil
        
        do {
            // ✅ Build conversation history (last 10 messages for context)
            let history = messages.suffix(10).map { msg -> [String: String] in
                return [
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.text
                ]
            }
            
            // ✅ Call function with history
            let reply = try await callChatbotFunction(
                userId: userId,
                question: trimmed,
                conversationHistory: Array(history)
            )
            
            let botMessage = ChatMessage(role: .assistant, text: reply)
            messages.append(botMessage)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error sending message:", error)
        }
        
        isSending = false
    }
    
    // ✅ UPDATED: Added conversationHistory parameter
    private func callChatbotFunction(
        userId: String,
        question: String,
        conversationHistory: [[String: String]]
    ) async throws -> String {
        struct ResponseBody: Decodable {
            let reply: String
        }
        
        // ✅ Create an Encodable struct for the request body
        struct RequestBody: Encodable {
            let user_id: String
            let question: String
            let conversation_history: [[String: String]]
        }
        
        let client = SupabaseManager.shared.client
        
        let requestBody = RequestBody(
            user_id: userId,
            question: question,
            conversation_history: conversationHistory
        )
        
        let response: ResponseBody = try await client.functions.invoke(
            "chatbot",
            options: FunctionInvokeOptions(body: requestBody)
        )
        
        return response.reply
    }

}
