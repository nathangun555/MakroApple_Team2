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
}
