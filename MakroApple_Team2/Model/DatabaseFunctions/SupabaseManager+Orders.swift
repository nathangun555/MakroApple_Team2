//
//  SupabaseManager+Orders.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    func fetchAllOrders(for userId: UUID? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [OrderRecord] {
        var base = client.from("orders").select()

        if let userId {
          base = base.eq("user_id", value: userId)
        }

        if let limit, let offset {
          let response = try await base
            .range(from: offset, to: offset + limit - 1)
            .execute()
          return try JSONDecoder().decode([OrderRecord].self, from: response.data)
        } else if let limit {
          let response = try await base
            .limit(limit)
            .execute()
          return try JSONDecoder().decode([OrderRecord].self, from: response.data)
        } else {
          let response = try await base.execute()
          return try JSONDecoder().decode([OrderRecord].self, from: response.data)
        }
    }
    
    func fetchOrder(id: UUID) async throws -> OrderRecord {
        let response = try await client
            .from("orders")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        return try JSONDecoder().decode(OrderRecord.self, from: response.data)
    }
    
    func createOrder(
        orderId: String,
        userId: UUID,
        parsedOrder: [String: Any],
        photoURLs: [String] = []
    ) async throws -> OrderRecord {
        var orderData: [String: AnyCodable?] = [:]
        
        var newOrderId: UUID
        
        if orderId != "" {
            newOrderId = UUID(uuidString: orderId)!
        } else {
            newOrderId = UUID()
        }
        
        orderData["id"] = AnyCodable(newOrderId.uuidString)
        orderData["user_id"] = AnyCodable(userId.uuidString)
        
        let date = Date()
        let orderYear = Calendar.current.component(.year, from: date)
        let startDate = "\(orderYear)-01-01 00:00:00+00"
        let endDate = "\(orderYear)-12-31 23:59:59+00"

        let response = try await client
            .from("orders")
            .select("id", count: CountOption.exact)
            .eq("user_id", value: userId)
            .gte("invoice_date", value: startDate)
            .lte("invoice_date", value: endDate)
            .execute()

        let orderCount = response.count ?? 0

        
        let orderNumber = DateFormatterHelper.generateInvoiceNumber(orderDate: Date(), orderCount: orderCount)
        orderData["order_number"] = AnyCodable(orderNumber)
        
        orderData["status"] = AnyCodable("Belum Terbayar")
        orderData["customer_order_name"] = AnyCodable(parsedOrder["Nama Pemesan"] as? String ?? "")
        orderData["customer_order_phone"] = AnyCodable(parsedOrder["No. Telp Pemesan"] as? String ?? "")
        orderData["customer_receiver_name"] = AnyCodable(parsedOrder["Nama Penerima"] as? String ?? "")
        orderData["customer_receiver_phone"] = AnyCodable(parsedOrder["No. Telp Penerima"] as? String ?? "")
        orderData["shipping_address"] = AnyCodable(parsedOrder["Alamat Kirim"] as? String ?? "")
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let pesananDateRaw = parsedOrder["Tanggal Pesanan"] as? String ?? DateFormatterHelper.formattedDate(now, showTime: false)
        print(pesananDateRaw)
        let jamKirimRaw = (parsedOrder["Jam Kirim"] as? String)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "23:59"
        print(jamKirimRaw)

        let pesananDateTimeISO = !pesananDateRaw.isEmpty
            ? DateFormatterHelper.dateTimeToISO(dateString: pesananDateRaw, timeString: jamKirimRaw)
            : nil

        orderData["order_dday_date"] = pesananDateTimeISO != nil ? AnyCodable(pesananDateTimeISO!) : nil


        let invoiceDueRaw = parsedOrder["Tanggal Jatuh Tempo"] as? String ?? ""
        let invoiceDueISO = (!invoiceDueRaw.isEmpty ? DateFormatterHelper.dateToISO(invoiceDueRaw) : nil)
        orderData["invoice_due_date"] = invoiceDueISO != nil ? AnyCodable(invoiceDueISO!) : nil

        orderData["add_on"] = AnyCodable(parsedOrder["Adds-on"] as? String ?? "")
        orderData["notes"] = AnyCodable(parsedOrder["Notes"] as? String ?? "")

        orderData["opsi_pengiriman"] = AnyCodable(parsedOrder["Pengiriman Kurir / Pickup"] as? String ?? "")
        orderData["subtotal"] = AnyCodable(0)
        orderData["shipping_cost"] = AnyCodable(0)
        orderData["discount_amount"] = AnyCodable(0)
        orderData["total_amount"] = AnyCodable(0)
        orderData["invoice_url"] = nil

        // Primary photo URLs
        orderData["photo_url_1"] = AnyCodable(photoURLs.count > 0 ? photoURLs[0] : "")
        orderData["photo_url_2"] = AnyCodable(photoURLs.count > 1 ? photoURLs[1] : "")
        orderData["photo_url_3"] = AnyCodable(photoURLs.count > 2 ? photoURLs[2] : "")

        // Handle everything else as custom fields
        let reservedKeys: Set<String> = [
            "Nama Pemesan", "No. Telp Pemesan", "No Telp Pemesan", "Nama Penerima", "No. Telp Penerima",
            "No Telp Penerima", "Alamat Kirim", "Tanggal Pesanan", "Jam Kirim", "Pesanan", "Adds-on",
            "Notes", "Pengiriman: Kurir / Pickup"
        ]
        
        var customFields: [String: Any] = [:]
        for (key, value) in parsedOrder {
            if !reservedKeys.contains(key) {
                customFields[key] = value
            }
        }

        if !customFields.isEmpty {
            orderData["custom_fields"] = AnyCodable(customFields)
        }

        orderData["created_at"] = AnyCodable(ISO8601DateFormatter().string(from: Date()))
        orderData["updated_at"] = AnyCodable(ISO8601DateFormatter().string(from: Date()))

        let insertResponse = try await client
            .from("orders")
            .upsert(orderData, onConflict: "id")
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        let order = try decoder.decode(OrderRecord.self, from: insertResponse.data)

        print("✅ Order created: \(order.id)")
        return order
    }
    
    
    
    func updateOrder(
            orderId: UUID,
            invoiceDate: String,
            invoiceDueDate: String?,
            subtotal: Decimal,
            shippingCost: Decimal,
            totalAmount: Decimal,
            discountAmount: Decimal = 0,
            customFields: [String: AnyCodable]? = nil,
            downPayment: Decimal?
        ) async throws -> OrderRecord {
            
            let subtotalDouble = NSDecimalNumber(decimal: subtotal).doubleValue
            let shippingDouble = NSDecimalNumber(decimal: shippingCost).doubleValue
            let totalDouble = NSDecimalNumber(decimal: totalAmount).doubleValue
            let discountDouble = NSDecimalNumber(decimal: discountAmount).doubleValue
            let downDouble = NSDecimalNumber(decimal: downPayment ?? 0).doubleValue
            
            var updateData: [String: AnyCodable] = [
                "invoice_date": AnyCodable(invoiceDate),
                "invoice_due_date": AnyCodable(invoiceDueDate),
                "subtotal": AnyCodable(subtotalDouble),
                "shipping_cost": AnyCodable(shippingDouble),
                "total_amount": AnyCodable(totalDouble),
                "discount_amount": AnyCodable(discountDouble),
                "updated_at": AnyCodable(ISO8601DateFormatter().string(from: Date())),
                "down_payment": AnyCodable(downDouble)
            ]
            
            let response = try await client
                .from("orders")
                .update(updateData)
                .eq("id", value: orderId.uuidString)
                .select()
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let updatedOrder = try decoder.decode(OrderRecord.self, from: response.data)
            
            print("✅ Order updated: \(updatedOrder.id)")
            return updatedOrder
        }
    
    func updateOrderInvoiceURL(orderId: UUID, invoiceURL: String) async throws -> OrderRecord {
        let updateData: [String: AnyCodable] = [
            "invoice_url": AnyCodable(invoiceURL),
            "updated_at": AnyCodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        let response = try await client
            .from("orders")
            .update(updateData)
            .eq("id", value: orderId.uuidString)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(OrderRecord.self, from: response.data)
    }
    
    func updateOrderStatus(orderId: UUID, newStatus: String) async throws {
            let response = try await client
                .from("orders")
                .update(["status": newStatus])
                .eq("id", value: orderId)
                .select()
                .execute()
            
            // Optional: check if update actually succeeded
            if response.status != 200 {
                throw NSError(domain: "SupabaseError", code: response.status, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to update order status"
                ])
            }
        }
    
    func deleteOrderCompletely(orderId: UUID) async throws {

        _ = try await client
            .from("order_items")
            .delete()
            .eq("order_id", value: orderId.uuidString)
            .execute()

        print("🗑️ Deleted items for order \(orderId)")

        _ = try await client
            .from("orders")
            .delete()
            .eq("id", value: orderId.uuidString)
            .execute()

        print("🗑️ Deleted order \(orderId)")
    }

}

