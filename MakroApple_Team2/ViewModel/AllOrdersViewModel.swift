import SwiftUI
import Foundation

@Observable
class AllOrdersViewModel {
    
    var businessName: String = ""
    var isLoading = false
    var errorMessage: String?
    var orders: [OrderRecord] = []
    var orderItems: [OrderItemRecord] = []

    // MARK: - Fetch Business Name
    func fetchBusinessName(for userId: UUID?) async {
        guard let userId else {
            errorMessage = "❌ Invalid user ID"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if let user = try await SupabaseManager.shared.fetchUser(by: userId) {
                businessName = user.businessName ?? "No Business Name"
                print("✅ Business Name Loaded:", businessName)
            } else {
                errorMessage = "User not found"
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Fetch user failed:", error)
        }
    }
    
    // MARK: - Fetch Orders
    func fetchOrders(for userId: UUID?) async {
        guard let userId else {
            print("❌ Invalid user ID")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedOrders = try await SupabaseManager.shared.fetchAllOrders(for: userId)
            self.orders = fetchedOrders
            print("✅ Orders fetched:", fetchedOrders.count)
        } catch {
            print("❌ Error fetching orders:", error)
        }
    }
    
    // MARK: - Fetch Order Items
    func fetchOrderItems(for userId: UUID?) async {
        guard let userId else {
            print("❌ Invalid user ID")
            return
        }

        isLoading = true
        defer { isLoading = false }
        
        do {
            let orderItems = try await SupabaseManager.shared.fetchOrderItems(userId: userId)
            self.orderItems = orderItems
            print("✅ Ditemukan \(orderItems.count) order items untuk user \(userId)")
        } catch {
            print("❌ Gagal ambil order items:", error.localizedDescription)
        }
    }
}
