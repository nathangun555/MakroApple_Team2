//
//  Order.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 14/10/25.
//

import SwiftUI

struct Order: Identifiable {
    var id: Int
    var customer_order_name: String
    var customer_order_phone: Int
    var productName: String
    var orderDate: Date
    var orderStatus: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: orderDate)
    }
}
