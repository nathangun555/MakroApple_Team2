//
//  Order.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 13/10/25.
//

import SwiftUI

struct Order: Identifiable {
    let id = UUID()
    let customerName: String
    let date: Date
    let items: [String]
    let total: Double
}
