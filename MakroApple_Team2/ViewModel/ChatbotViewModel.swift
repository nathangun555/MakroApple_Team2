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

    func sendMessage(userId: String) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        let userMessage = ChatMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        inputText = ""
        isSending = true
        errorMessage = nil

        do {
            let reply = try await callChatbotFunction(userId: userId, question: trimmed)
            let botMessage = ChatMessage(role: .assistant, text: reply)
            messages.append(botMessage)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    private func callChatbotFunction(userId: String, question: String) async throws -> String {
        // Panggil Supabase Edge Function "chatbot"
        struct ResponseBody: Decodable {
            let reply: String
            let intent: String?
        }

        let client = SupabaseManager.shared.client

        let response: ResponseBody = try await client.functions.invoke(
            "chatbot",
            options: FunctionInvokeOptions(
                body: [
                    "user_id": userId,
                    "question": question
                ]
            )
        )

        return response.reply
    }
}
