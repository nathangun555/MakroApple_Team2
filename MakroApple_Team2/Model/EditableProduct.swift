//
//  EditableProduct.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 27/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class EditableProduct: ObservableObject, Identifiable {
    let id: UUID
    let original: ProductRecord

    @Published var name: String
    @Published var price: Decimal
    @Published var productType: String?
    @Published var isNew: Bool
    @Published var pendingDelete: Bool = false // ✅ tandai produk untuk dihapus

    init(record: ProductRecord, isNew: Bool = false) {
        self.id = record.id
        self.original = record
        self.name = record.name
        self.price = record.price
        self.productType = record.productType
        self.isNew = isNew
    }

    var hasChanges: Bool {
        return name != original.name
        || price != original.price
        || (productType ?? "") != (original.productType ?? "")
    }

    func changedFieldsPayload() -> [String: Any] {
        var out: [String: Any] = [:]
        if name != original.name { out["name"] = name }
        if price != original.price {
            let dbl = Double(truncating: NSDecimalNumber(decimal: price))
            out["price"] = dbl
        }
        if (productType ?? "") != (original.productType ?? "") {
            out["product_type"] = productType ?? NSNull()
        }
        return out
    }
}
