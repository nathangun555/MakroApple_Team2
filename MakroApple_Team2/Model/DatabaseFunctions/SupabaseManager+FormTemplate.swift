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

      var templateDict: [String: Any]?
      if let formTemplate = formTemplate,
         let data = formTemplate.data(using: .utf8),
         let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
          templateDict = dict
      }
      
      let payload: [String: AnyCodable] = [
          "id": AnyCodable(id.uuidString),
          "template_format": AnyCodable(templateDict ?? [:])
      ]
      
      let response = try await client
          .from("users")
          .upsert(payload, onConflict: "id")
          .select()
          .single()
          .execute()

      print("Raw response data:", String(data: response.data, encoding: .utf8) ?? "Unable to decode")
      
      return try JSONDecoder().decode(UserRecord.self, from: response.data)
  }
}
