//
//  SupabaseManager+Order_Items.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//
    
import Foundation
import Supabase

extension SupabaseManager {
    
    // Ambil semua item berdasarkan user_id
    func fetchOrderItems(userId: UUID) async throws -> [OrderItemRecord] {
        
        let orders = try await fetchAllOrders(for: userId)
        let orderIds = orders.map { $0.id }
        
        guard !orderIds.isEmpty else { return [] }

        let response = try await client
            .from("order_items")
            .select()
            .in("order_id", values: orderIds)
            .execute()

        let items = try JSONDecoder().decode([OrderItemRecord].self, from: response.data)
        return items
    }
    
    // Ambil semua item berdasarkan orderId
    func fetchOrderItem(orderId: UUID) async throws -> [OrderItemRecord] {
        let response = try await client
            .from("order_items")
            .select()
            .eq("order_id", value: orderId.uuidString)
            .execute()
        return try JSONDecoder().decode([OrderItemRecord].self, from: response.data)
    }
    
    func createOrderItems(products: [ProductItem], orderId: UUID) async throws -> [OrderItemRecord] {
        let nowString = ISO8601DateFormatter().string(from: Date())
//        let orderItemId = UUID()
        let productId = UUID()
        let itemRows: [[String: AnyCodable]] = products
            .filter { !$0.name.isEmpty }
            .map { product in
                [
                    "id": AnyCodable(UUID().uuidString),
                    "order_id": AnyCodable(orderId.uuidString),
                    "product_id": AnyCodable(productId),
                    "product_name": AnyCodable(product.name),
                    "product_price": AnyCodable(0.00),
                    "product_type": AnyCodable(""),
                    "quantity": AnyCodable(product.quantity),
                    "subtotal": AnyCodable(0.00),
                    "created_at": AnyCodable(nowString),
                    "updated_at": AnyCodable(nowString)
                ]
            }
        
        guard !itemRows.isEmpty else { return [] }
        
        let response = try await client
            .from("order_items")
            .insert(itemRows)
            .select()
            .execute()
        
        let decoder = JSONDecoder()
        let orderItems = try decoder.decode([OrderItemRecord].self, from: response.data)
        return orderItems
    }
    
    func updateOrderItems(id: UUID, order: [OrderItemRecord]) async throws -> [OrderItemRecord] {
        
        let response = try await client
            .from("order_items")
            .upsert(order, onConflict: "id")
            .eq("order_id", value: id.uuidString)
            .select()
            .execute()

        print("Raw response data:", String(data: response.data, encoding: .utf8) ?? "Unable to decode")
        
        return try JSONDecoder().decode([OrderItemRecord].self, from: response.data)
    }
    
    func deleteOrder(for orderId: UUID) async throws {
        let response = try await client
            .from("orders")
            .delete()
            .eq("id", value: orderId.uuidString)
            .execute()
        
        print("🗑️ Deleted order for order_id:", orderId)
        print("Response:", String(data: response.data, encoding: .utf8) ?? "No response data")
    }
    
    func deleteOrderItems(for orderId: UUID) async throws {
        let response = try await client
            .from("order_items")
            .delete()
            .eq("order_id", value: orderId.uuidString)
            .execute()
        
        print("🗑️ Deleted order items for order_id:", orderId)
        print("Response:", String(data: response.data, encoding: .utf8) ?? "No response data")
    }
}
