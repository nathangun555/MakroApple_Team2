//
//  Order.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 13/10/25.


import SwiftUI

struct Order: Identifiable {
    var id = UUID()
    var customer_order_name: String
    var customer_order_phone: String
    var productName: [String]
    var orderDate: Date
    var orderStatus: String
    var total: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: orderDate)
    }
}
