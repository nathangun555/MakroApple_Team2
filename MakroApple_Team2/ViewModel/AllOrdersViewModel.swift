import SwiftUI
import Foundation

@Observable
class AllOrdersViewModel {
    
    
    private let calendar = Calendar.current
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
    

//    func hasOrders(for date: Date) -> Bool {
//        return viewModel.orders.contains { calendar.isDate($0.orderDdayDate, inSameDayAs: date) }
//    }
    
    func hasOrders(for date: Date) -> Bool {
       
        return orders.contains { order in
            guard let orderDate = DateFormatterHelper.toDate(order.orderDdayDate ?? "") else {
                return false
            }
            let isValidStatus = order.status != "Belum Terbayar" && order.status != "Dibatalkan"
            return isValidStatus && Calendar.current.isDate(orderDate, inSameDayAs: date)
        }
    }
    
    func ordersForDate(for date: Date) -> [OrderRecord] {
        return orders.filter { order in
            guard let orderDate = DateFormatterHelper.toDate(order.orderDdayDate ?? "") else {
                return false
            }
            let isValidStatus = order.status != "Belum Terbayar" && order.status != "Dibatalkan"
            return isValidStatus && Calendar.current.isDate(orderDate, inSameDayAs: date)
        }
    }


    func formattedMonthYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }

    func generateDays(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }
        
        var days: [Date] = []
        (0..<42).forEach { i in
            if let day = calendar.date(byAdding: .day, value: i, to: firstWeek.start) {
                days.append(day)
            }
        }
        return days
    }
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    func updateOrderStatus(for order: OrderRecord) async {
        var nextStatus: String
        
        switch order.status {
        case "belum terbayar": nextStatus = "diproses"
        case "diproses": nextStatus = "dikirim"
        case "dikirim": nextStatus = "selesai"
        default: return
        }
        
    }

}
