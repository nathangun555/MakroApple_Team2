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
}
