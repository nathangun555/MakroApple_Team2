//
//  OrderFieldHelper.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 30/10/25.
//

import Foundation

struct OrderFieldHelper {
    
    static let fieldMapping: [String: String] = [
        "Nama Pemesan": "customer_order_name",
        "No. Telp Pemesan": "customer_order_phone",
        "Nama Penerima": "customer_receiver_name",
        "No. Telp Penerima": "customer_receiver_phone",
        "Alamat Kirim": "shipping_address",
        "Tanggal Pesanan": "order_dday_date",
        "Jam Kirim": "order_dday_date",
        "Notes": "notes",
        "Adds-on": "add_on",
        "Pengiriman": "opsi_pengiriman",
        "Pesanan": "order_items",  
    ]
    
    static func mapToOrderRecord(
        parsedOrder: [String: Any],
        userId: UUID
    ) -> (order: [String: Any], items: [[String: Any]], customFields: [String: Any]) {
        
        var orderData: [String: Any] = [:]
        var customFields: [String: Any] = [:]
        var orderItems: [[String: Any]] = []
        
        let orderNumber = generateOrderNumber()
        orderData["order_number"] = orderNumber
        orderData["user_id"] = userId.uuidString
        orderData["status"] = "Belum Terbayar"
        
        for (templateKey, value) in parsedOrder {
            if let dbColumn = fieldMapping[templateKey] {
                switch dbColumn {
                case "order_items":
                    orderItems = extractOrderItems(from: value)
                    
                case "add_on":
                    orderData["add_on"] = extractAddOns(from: value)
                    
                case "order_dday_date":
                    // Combine date and time if both exist
                    if templateKey == "Tanggal Pesanan" {
                        orderData["order_dday_date"] = formatDate(value)
                    }
                    
                default:
                    // Regular field mapping
                    orderData[dbColumn] = value
                }
            } else {
                // ✅ Unmapped field → goes to custom_fields
                customFields[templateKey] = value
            }
        }
        
        // Add custom fields to order data
        if !customFields.isEmpty {
            orderData["custom_fields"] = customFields
        }
        
        // Set default financial values
        orderData["subtotal"] = 0.0
        orderData["shipping_cost"] = 0.0
        orderData["discount_amount"] = 0.0
        orderData["total_amount"] = 0.0
        
        return (orderData, orderItems, customFields)
    }
    
    // ✅ Extract order items from parsed array
    private static func extractOrderItems(from value: Any) -> [[String: Any]] {
        guard let itemsArray = value as? [[String: Any]] else {
            return []
        }
        
        return itemsArray.map { item in
            [
                "product_name": item["item"] ?? "",
                "quantity": item["quantity"] ?? 1,
                "product_price": 0.0,
                "subtotal": 0.0,
                "product_type": "custom"
            ]
        }
    }
    
    // ✅ Extract add-ons and format as string
    private static func extractAddOns(from value: Any) -> String {
        guard let addOnsArray = value as? [[String: Any]] else {
            return ""
        }
        
        let addOnStrings = addOnsArray.map { item in
            let name = item["item"] as? String ?? ""
            let qty = item["quantity"] as? Int ?? 1
            return "\(qty)x \(name)"
        }
        
        return addOnStrings.joined(separator: ", ")
    }
    
    // ✅ Format date string
    private static func formatDate(_ value: Any) -> String {
        guard let dateString = value as? String else {
            return ""
        }
        // You can add date parsing logic here
        return dateString
    }
    
    // ✅ Generate unique order number
    private static func generateOrderNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        let randomSuffix = String(format: "%04d", Int.random(in: 0...9999))
        return "ORD-\(dateString)-\(randomSuffix)"
    }
}
