//
//  SupabaseManager+Products.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    // MARK: - Insert Product
    func insertProduct(name: String, price: Double, productType: String, userId: UUID) async throws -> ProductRecord {
        struct NewProductPayload: Encodable {
            let id: String
            let user_id: String
            let name: String
            let price: Double
            let product_type: String
            let is_active: Bool
            let created_at: String
            let updated_at: String
        }

        let now = ISO8601DateFormatter().string(from: Date())
        let newId = UUID().uuidString  // ✅ Generate UUID di sisi app

        let payload = NewProductPayload(
            id: newId,
            user_id: userId.uuidString,
            name: name,
            price: price,
            product_type: productType,
            is_active: true,
            created_at: now,
            updated_at: now
        )

        let response = try await client
            .from("products")
            .insert(payload)
            .select()
            .single()
            .execute()

        print("🆕 Insert response:", String(data: response.data, encoding: .utf8) ?? "nil")

        if response.data.isEmpty {
            throw NSError(domain: "Insert failed", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response data from insert."])
        }

        let record = try JSONDecoder().decode(ProductRecord.self, from: response.data)
        return record
    }


    // MARK: - Update Product
    func updateProduct(id: UUID, values: [String: Any]) async throws -> ProductRecord {
        print("🧩 Updating product id:", id)
        print("📦 Update payload:", values)

        let encodableValues: [String: AnyEncodable] = values.mapValues(AnyEncodable.init)

        let response = try await client
            .from("products")
            .update(encodableValues)
            .eq("id", value: id.uuidString) // ✅ pakai string agar pasti match
            .select()
            .execute()

        print("🌀 Supabase update raw response:", String(data: response.data, encoding: .utf8) ?? "nil")
        print("🧾 Status:", response.status)

        // Decode langsung kalau ada isi
        if !response.data.isEmpty {
            let records = try JSONDecoder().decode([ProductRecord].self, from: response.data)
            if let first = records.first {
                return first
            }
        }

        // 🩵 Fallback refetch
        print("⚠️ Empty response, refetching product by id \(id.uuidString)...")
        let refetch = try await client
            .from("products")
            .select()
            .eq("id", value: id.uuidString)
            .execute()

        print("🔁 Refetch raw response:", String(data: refetch.data, encoding: .utf8) ?? "nil")

        let refetchedRecords = try JSONDecoder().decode([ProductRecord].self, from: refetch.data)
        guard let first = refetchedRecords.first else {
            throw NSError(
                domain: "SupabaseUpdateError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No updated record returned after refetch"]
            )
        }
        return first
    }

    // MARK: - Fetch Products
    func fetchProducts(for userId: UUID, limit: Int? = nil, offset: Int? = nil) async throws -> [ProductRecord] {
        var query = client
            .from("products")
            .select()
            .eq("user_id", value: userId.uuidString) //

        if let limit, let offset {
            query = query.range(from: offset, to: offset + limit - 1) as! PostgrestFilterBuilder
        } else if let limit {
            query = query.limit(limit) as! PostgrestFilterBuilder
        }

        let response = try await query.execute()
        print("📦 Fetch response:", String(data: response.data, encoding: .utf8) ?? "nil")

        return try JSONDecoder().decode([ProductRecord].self, from: response.data)
    }
    
    // MARK: - Delete Product(s)
        /// Delete single product by id. Does not require returned row.
        func deleteProduct(id: UUID) async throws {
            print("🗑️ Deleting product id:", id.uuidString)
            let response = try await client
                .from("products")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            // Log raw response for debugging
            print("🗑️ Delete raw response:", String(data: response.data, encoding: .utf8) ?? "nil")
            print("🗑️ Status:", response.status)

            // If server returns HTTP error status, throw
            let statusCode = response.status ?? 0
            if statusCode >= 400 {
                throw NSError(domain: "SupabaseDeleteError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete product (status \(statusCode))."])
            }

            // Note: Supabase may return empty data on delete; that's fine.
        }

        /// Delete multiple products by ids (helper)
        func deleteProducts(ids: [UUID]) async throws {
            guard !ids.isEmpty else { return }
            // convert UUIDs to string array
            let idStrings = ids.map { $0.uuidString }
            print("🗑️ Deleting products ids:", idStrings)
            // Use PostgREST IN filter with "in" (the library might support .in)
            // If your Supabase swift SDK exposes `.in` method, use it; otherwise do loop fallback.
            if let builder = client.from("products") as? PostgrestFilterBuilder {
                // Attempt to use `in` via filter builder if available
                // NOTE: If your SDK doesn't expose `.in`, fallback to per-id deletes below.
                // Fallback simple loop:
                for id in ids {
                    try await deleteProduct(id: id)
                }
            } else {
                for id in ids {
                    try await deleteProduct(id: id)
                }
            }
        }
    
    
    func deleteProductsByCategory(userId: UUID, productType: String) async throws {
      _ = try await client
        .from("products")
        .delete()
        .eq("user_id", value: userId)
        .eq("product_type", value: productType)
        .execute()
    }
    
    func bulkRenameCategory(userId: UUID, from oldType: String, to newType: String) async throws {
      _ = try await client
        .from("products")
        .update(["product_type": newType])
        .eq("user_id", value: userId)
        .eq("product_type", value: oldType)
        .execute()
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

