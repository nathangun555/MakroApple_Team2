//
//  Menu.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 07/11/25.
//

import SwiftUI

struct MenuCategory: Codable {
    let categoryName: String
    let products: [MenuProduct]
    
    enum CodingKeys: String, CodingKey {
        case categoryName = "category_name"
        case products
    }
}

struct MenuProduct: Codable {
    let name: String
    let price: Double
    let notes: String?
    let productType: String
    
    enum CodingKeys: String, CodingKey {
        case name, price, notes
        case productType = "product_type"
    }
}

struct MenuScanResponse: Codable {
    let categories: [MenuCategory]
}
