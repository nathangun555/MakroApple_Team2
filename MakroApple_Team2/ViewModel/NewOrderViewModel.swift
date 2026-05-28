//
//  NewOrderViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 28/10/25.
//

import SwiftUI
import Foundation
import Observation

@Observable
@MainActor
class NewOrderViewModel {
    var userRecord: UserRecord?
    var errorMessage: String?
    var isLoading: Bool = false
    var didSave: Bool = false
    var showError = false
    
    var parsedOrderData: [String: Any]?
    var navigateToConfirm = false
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    func parseOrder(text: String) async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            showErrorAlert("User belum login")
            return
        }
    
        guard !text.isEmpty else {
            return
        }
        
        isLoading = true
        defer {
            isLoading = false
            print("🔵 isLoading set to false")
        }
        
        do {
            // Step 1: Fetch template
            guard let userRecord = try await SupabaseManager.shared.fetchFormTemplate(by: uuid) else {
                print("❌ userRecord is nil")
                showErrorAlert("Template belum dibuat")
                return
            }
            
            guard let templateFormat = userRecord.templateFormat else {
                showErrorAlert("Template belum dibuat")
                return
            }

            // Step 2: Unwrap AnyCodable to [String: Any]
            let template: [String: Any] = templateFormat.mapValues { anyCodable in
                return anyCodable.value
            }
            
            // Step 3: Prepare request
            guard let url = URL(string: "https://hddpofvkwanymugjtlpp.supabase.co/functions/v1/form-order") else {
                print("❌ Invalid URL")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhkZHBvZnZrd2FueW11Z2p0bHBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3ODczMTIsImV4cCI6MjA4MzM2MzMxMn0.47Ts6UPaoQHQhrQ2nVx8LnTxFuJxdjZUXbr0mkLw9cA", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "orderText": text,
                "template": template
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Step 4: Make API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Step 5: Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            print("🔵 HTTP Status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = errorJson["error"] as? String {
                    print("❌ Error message: \(errorMsg)")
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
            }
            
            // Step 6: Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ JSON parsed, keys: \(json.keys)")
                
                if let parsedOrder = json["parsedOrder"] as? [String: Any] {
                    print("✅ parsedOrder extracted, keys: \(parsedOrder.keys)")
                    print("\n📋 === PARSED ORDER DETAILS ===")
                    for (key, value) in parsedOrder {
                        print("  \(key): \(value)")
                    }
                    print("==============================\n")
                    self.parsedOrderData = parsedOrder
                    self.navigateToConfirm = true
                    print("HASIL NAVIGATE : \(navigateToConfirm)")
                } else {
                    print("❌ No 'parsedOrder' key in response")
                    print("Available keys: \(json.keys)")
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                }
            } else {
                print("❌ Failed to parse JSON")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }
            
        } catch {
            print("❌ Error caught: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            showErrorAlert("Gagal memproses pesanan: \(error.localizedDescription)")
        }
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}
