//
//  OrderCountHelper.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 19/11/25.
//

import Foundation

struct OrderCountHelper {
    static let validStatuses = ["diproses", "terkirim"]
    
    static func countTodayOrders(from orders: [OrderRecord]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return orders.filter { order in
            guard validStatuses.contains(order.status.lowercased()),
                  let date = DateFormatterHelper.toDate(order.orderDdayDate) else { return false }
            return Calendar.current.startOfDay(for: date) == today
        }.count
    }
    
    static func countTomorrowOrders(from orders: [OrderRecord]) -> Int {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        return orders.filter { order in
            guard validStatuses.contains(order.status.lowercased()),
                  let date = DateFormatterHelper.toDate(order.orderDdayDate) else { return false }
            return calendar.startOfDay(for: date) == tomorrow
        }.count
    }
}
