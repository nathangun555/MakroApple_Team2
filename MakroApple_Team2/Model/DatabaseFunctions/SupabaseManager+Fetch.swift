//
//  SupabaseManager+Fetch.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 15/10/25.
//

// Ini contoh doang , delete gapapa


import Foundation
import Supabase

extension SupabaseManager {
    func fetchAllUsers() async throws -> [UserRecord] {
        let response = try await client
            .from("users")
            .select()
            .execute()

        // New way: decode from response.data, not response.value
        return try JSONDecoder().decode([UserRecord].self, from: response.data)
    }

    func fetchAllOrders() async throws -> [OrderRecord] {
        let response = try await client
            .from("orders")
            .select()
            .execute()

        return try JSONDecoder().decode([OrderRecord].self, from: response.data)
    }
}

