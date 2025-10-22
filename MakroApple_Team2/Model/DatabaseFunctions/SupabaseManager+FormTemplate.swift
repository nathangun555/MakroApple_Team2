//
//  SupabaseManager+FormTemplate.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
  func fetchFormTemplate(by id: UUID) async throws -> UserRecord? {
    let response = try await client
      .from("users")
      .select("templateFormat")
      .eq("id", value: id)
      .limit(1)
      .execute()

    let rows = try JSONDecoder().decode([UserRecord].self, from: response.data)
    return rows.first
  }

  @discardableResult
  func upsertFormTemplate(id: UUID, formTemplate: String?) async throws -> UserRecord {

      let payload: [String: AnyCodable?] = [
          "id": AnyCodable(id),
          "templateFormat": formTemplate.map(AnyCodable.init)
        ]
      
      let response = try await client
      .from("users")
      .upsert(payload, onConflict: "id")
      .select()
      .single()
      .execute()

    return try JSONDecoder().decode(UserRecord.self, from: response.data)
  }
}
