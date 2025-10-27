////
////  ActiveOrdersViewModel.swift
////  MakroApple_Team2
////
////  Created by Alfred Hans Witono on 15/10/25.
////
//
//import SwiftUI
//import Foundation
//import Combine
//import Observation
//
//@Observable
//class ActiveOrdersViewModel {
//    private let calendar = Calendar.current
//    private let viewModel = AllOrdersViewModel()
//
////    func hasOrders(for date: Date) -> Bool {
////        return viewModel.orders.contains { calendar.isDate($0.orderDdayDate, inSameDayAs: date) }
////    }
//    
//    func hasOrders(for date: Date) -> Bool {
//        return viewModel.orders.contains { order in
//            guard let orderDate = DateFormatterHelper.toDate(order.orderDdayDate ?? "nil") else { return false }
//            return Calendar.current.isDate(orderDate, inSameDayAs: date)
//        }
//    }
//
//    func ordersForDate(for date: Date) -> [Order] {
//        return viewModel.orders.filter { order in
//            guard let orderDate = DateFormatterHelper.toDate(order.orderDdayDate ?? "nil" ) else { return false }
//            return Calendar.current.isDate(orderDate, inSameDayAs: date)
//        } as! [Order]
//    }
//
//    func formattedMonthYear(for date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMMM yyyy"
//        return formatter.string(from: date).uppercased()
//    }
//
//    func generateDays(for month: Date) -> [Date] {
//        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
//              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
//        else { return [] }
//        
//        var days: [Date] = []
//        (0..<42).forEach { i in
//            if let day = calendar.date(byAdding: .day, value: i, to: firstWeek.start) {
//                days.append(day)
//            }
//        }
//        return days
//    }
//    struct ScrollOffsetPreferenceKey: PreferenceKey {
//        static var defaultValue: CGFloat = 0
//        
//        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//            value = nextValue()
//        }
//    }
//
//}
