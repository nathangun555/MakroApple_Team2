//
//  AsParsedDictionaryHelper.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 24/11/25.
//

// ONLY COMPATIBLE FOR EDITORDERDETAILVIEW/EDITORDERVIEW

import SwiftUI

extension OrderRecord {
    func asParsedDictionary(with orderItems: [OrderItemRecord]) -> [String: Any] {
        var dict: [String: Any] = [
            "Nama Pemesan": customerOrderName,
            "No. Telp Pemesan": customerOrderPhone ?? "",
            "Nama Penerima": customerReceiverName ?? "",
            "No. Telp Penerima": customerReceiverPhone ?? "",
            "Alamat Kirim": shippingAddress ?? "",
            "Tanggal Pesanan": DateFormatterHelper.formattedDate(orderDdayDate ?? ""),
            "Jam Kirim": DateFormatterHelper.formattedTime(orderDdayDate ?? "")
        ]
        
        dict["Pesanan"] = orderItems.map { item in
            [
                "item": item.productName,
                "quantity": item.quantity
            ]
        }
        
        if let customFields = customFields {
            for (key, value) in customFields {
                dict[key] = value.value
            }
        }

        return dict
    }
}

