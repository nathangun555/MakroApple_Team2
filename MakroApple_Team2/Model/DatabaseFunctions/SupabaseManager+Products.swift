//
//  SupabaseManager+Products.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    // MARK: - Update Product
    func updateProduct(id: UUID, values: [String: Any]) async throws -> ProductRecord {
        print("🆔 Updating product with id:", id)
        print("🧩 Values before send:", values)

        let encodableValues = values.mapValues(AnyEncodable.init)

        // Kirim dictionary langsung TANPA JSONSerialization
        let response = try await client
            .from("products")
            .update(encodableValues)
            .eq("id", value: id)
            .select() // Supaya dapat data yang baru diubah
            .execute()

        print("🔹 Supabase update raw response:", String(data: response.data, encoding: .utf8) ?? "nil")
        print("🔹 Status:", response.status)

        // Kalau tidak ada data di response (meski jarang), fetch ulang
        if response.data.isEmpty {
            print("⚠️ Empty response, refetching product...")
            let refetch = try await client
                .from("products")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            print("🔹 Refetched data:", String(data: refetch.data, encoding: .utf8) ?? "nil")
            return try JSONDecoder().decode(ProductRecord.self, from: refetch.data)
        }

        let updatedRecords = try JSONDecoder().decode([ProductRecord].self, from: response.data)
        return updatedRecords.first!
    }

    // MARK: - Fetch Products
    func fetchProducts(for userId: UUID, limit: Int? = nil, offset: Int? = nil) async throws -> [ProductRecord] {
        // Base query
        let baseQuery = client
            .from("products")
            .select()
            .eq("user_id", value: userId)

        // Optional pagination
        let finalQuery: PostgrestTransformBuilder
        if let limit, let offset {
            finalQuery = baseQuery.range(from: offset, to: offset + limit - 1)
        } else if let limit {
            finalQuery = baseQuery.limit(limit)
        } else {
            finalQuery = baseQuery
        }

        let response = try await finalQuery.execute()
        print("Supabase update response before:", String(data: response.data, encoding: .utf8) ?? "nil")
        return try JSONDecoder().decode([ProductRecord].self, from: response.data)
    }
}

// MARK: - Type Erasure for Encodable values
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T>(_ value: T) {
        if let encodable = value as? Encodable {
            self._encode = { encoder in
                try encodable.encode(to: encoder)
            }
        } else {
            self._encode = { encoder in
                var container = encoder.singleValueContainer()
                try container.encodeNil()
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
