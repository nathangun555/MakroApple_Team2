//
//  StatusColors.swift
//  MakroApple_Team2
//
//  Created by Edward Suwandi on 29/12/25.
//

import SwiftUI

// Status Colors
let widgetStatusColors: [String: Color] = [
    "Belum Terbayar": .belumBayar,
    "Diproses": .diproses,
    "Terkirim": .terkirim,
    "Selesai": .selesai,
    "Dibatalkan": .dibatalkan
]

// Filter Status
extension Array where Element == OrderRecord {
    /// Filter status tertentu dan urutkan berdasarkan jam
    var filteredOrders: [OrderRecord] {
        self
            .filter { !["Belum Terbayar", "Dibatalkan"].contains($0.status) } // filter status
            .sorted {
                let date0 = ISO8601DateFormatter().date(from: $0.orderDdayDate ?? "") ?? Date.distantPast
                let date1 = ISO8601DateFormatter().date(from: $1.orderDdayDate ?? "") ?? Date.distantPast
                return date0 < date1
            }
    }
}

// Format Date
var dateComponents: (day: String, monthYear: String) {
    let date = Date()
    let day = Calendar.current.component(.day, from: date).description

    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    let monthYear = formatter.string(from: date)

    return (day, monthYear)
}
