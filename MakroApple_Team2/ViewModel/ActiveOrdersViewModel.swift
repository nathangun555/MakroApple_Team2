//
//  ActiveOrdersViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 15/10/25.
//

import SwiftUI
import Foundation
import Combine
import Observation

@Observable
class ActiveOrdersViewModel {
    private let calendar = Calendar.current
    // Dummy order data
    var sampleOrders: [Order] = [
        Order(
            customer_order_name: "Jane Stacey",
            customer_order_phone: "08123456789",
            productName: ["Strawberry Cheesecake XL"],
            orderDate: Date(),
            orderStatus: "Active",
            total: 125000
        ),
        Order(
            customer_order_name: "John Gunawan",
            customer_order_phone: "08987654321",
            productName: ["Burnt Cheesecake S"],
            orderDate: Date(),
            orderStatus: "Active",
            total: 75000
        ),
        Order(
            customer_order_name: "John Gunawan",
            customer_order_phone: "08987654321",
            productName: ["Burnt Cheesecake S"],
            orderDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            orderStatus: "Active",
            total: 75000
        )
    ]

    func hasOrders(for date: Date) -> Bool {
        return sampleOrders.contains { calendar.isDate($0.orderDate, inSameDayAs: date) }
    }
    
    func ordersForDate(for date: Date) -> [Order] {
            return sampleOrders.filter { calendar.isDate($0.orderDate, inSameDayAs: date) }
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

}
