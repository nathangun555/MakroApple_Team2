//
//  SupabaseManagers+Products.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
  func fetchProducts(for userId: UUID, limit: Int? = nil, offset: Int? = nil) async throws -> [ProductRecord] {
    // Build the base filter query first
    let baseQuery = client
      .from("products")
      .select()
      .eq("user_id", value: userId)

    // Apply pagination/transformations on top of the base query
    let finalQuery: PostgrestTransformBuilder
    if let limit, let offset {
      finalQuery = baseQuery.range(from: offset, to: offset + limit - 1)
    } else if let limit {
      finalQuery = baseQuery.limit(limit)
    } else {
      finalQuery = baseQuery
    }

    let response = try await finalQuery.execute()
    return try JSONDecoder().decode([ProductRecord].self, from: response.data)
  }
}
