//
//  SupabaseManager+Products.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    
    func hasAnyProduct(for userId: UUID) async throws -> Bool {
           let response = try await client
               .from("products")
               .select("id")
               .eq("user_id", value: userId.uuidString)
               .limit(1)
               .execute()

           // Jika SDK Anda punya decoding helper:
           // let rows: [ProductRecord] = try JSONDecoder().decode([ProductRecord].self, from: response.data)
           // return !rows.isEmpty

           // Tanpa decode, cukup cek data JSON length > 2 (bukan "[]")
           // Namun lebih baik decode agar robust:
           let rows = try JSONDecoder().decode([ProductRecord].self, from: response.data)
           return !rows.isEmpty
       }
    
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
            .eq("user_id", value: userId)

        if let limit, let offset {
            query = query.range(from: offset, to: offset + limit - 1) as! PostgrestFilterBuilder
        } else if let limit {
            query = query.limit(limit) as! PostgrestFilterBuilder
        }

        let response = try await query.execute()
        print("📦 Fetch response:", String(data: response.data, encoding: .utf8) ?? "nil")

        return try JSONDecoder().decode([ProductRecord].self, from: response.data)
    }
    
    // MARK: - Delete single product
       func deleteProduct(id: UUID) async throws {
           try await client
               .from("products")
               .delete()
               .eq("id", value: id)
               .execute()
       }

       // MARK: - Delete all products under a category
       func deleteProductsByCategory(_ category: String, userId: UUID) async throws {
           try await client
               .from("products")
               .delete()
               .eq("product_type", value: category)
               .eq("user_id", value: userId)
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
