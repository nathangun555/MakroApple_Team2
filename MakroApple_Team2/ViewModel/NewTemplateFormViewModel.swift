import SwiftUI
import Foundation
import Observation

@Observable
@MainActor
class NewTemplateViewModel {
    var userRecord: UserRecord?
    var errorMessage: String?
    var isLoading: Bool = false
    var didSave: Bool = false
    var resultJSON: String? = nil  // ✅ Add this
    
    private(set) var userId: String?
    let edgeFunctionURL = URL(string: "https://iznjcwyoziqjgfjahemb.supabase.co/functions/v1/form-template")!
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    // ✅ Move edge function logic here
    func generateTemplate(from input: String) async {
        guard !input.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        resultJSON = nil
        
        do {
            var request = URLRequest(url: edgeFunctionURL)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6bmpjd3lvemlxamdmamFoZW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MTg3NjksImV4cCI6MjA3MjI5NDc2OX0.J9zQpQajTg3V6qAN18W5Fkv2jCDobL_XzuRS3BdPmdA", forHTTPHeaderField: "Authorization")
            
            let body = ["input": input]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            if let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let outputObject = decoded["outputJson"] as? [String: Any] {
                if let jsonData = try? JSONSerialization.data(withJSONObject: outputObject, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    resultJSON = jsonString
                }
            } else {
                resultJSON = String(data: data, encoding: .utf8)
            }

            // ✅ Auto-save after successful generation
            await saveTemplate(templateString: resultJSON ?? "")
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveTemplate(templateString: String) async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        isLoading = true
        errorMessage = nil
        didSave = false
        defer { isLoading = false }
        
        do {
            let updatedRecord = try await SupabaseManager.shared.upsertFormTemplate(
                id: uuid,
                formTemplate: templateString
            )
            self.userRecord = updatedRecord
            self.errorMessage = nil
            self.didSave = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
