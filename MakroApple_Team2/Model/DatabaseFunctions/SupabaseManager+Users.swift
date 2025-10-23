//
//  SupabaseManager+Users.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//


//import Foundation
//import Supabase
//
//extension SupabaseManager {
//    func fetchUser(by userId: UUID) async throws -> UserRecord? {
//        let response = try await client
//            .from("users")
//            .select("*")
//            .eq("id", value: userId)
//            .limit(1)
//            .execute()
//
//        print("✅ Raw Supabase data:", String(data: response.data, encoding: .utf8) ?? "nil")
//
//        let decoded = try JSONDecoder().decode([UserRecord].self, from: response.data)
//        return decoded.first
//    }
//}

//
//  SupabaseManager+Users.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 17/10/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    
    func deleteUserCompletely() async throws {
           _ = try await client
                .rpc("app_delete_user_fully", params: [String: String]())
                .execute()
         }
    
  func fetchUser(by id: UUID) async throws -> UserRecord? {
    let response = try await client
      .from("users")
      .select()
      .eq("id", value: id)
      .limit(1)
      .execute()

    let rows = try JSONDecoder().decode([UserRecord].self, from: response.data)
    return rows.first
  }

  @discardableResult
  func upsertUser(
    id: UUID,
    businessName: String?,
    businessPhone: String?,
    businessAddress: String?,
    businessLogoUrl: String?,
    businessEmail: String?,
    bankAccountNumber: String?,
    bankAccountName: String?,
    bankName: String?
  ) async throws -> UserRecord {

    func nz(_ s: String?) -> String? {
      guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
      return s
    }

    // Build body and drop nils
    let raw: [String: AnyCodable?] = [
      "id": AnyCodable(id),
      "business_name": nz(businessName).map(AnyCodable.init),
      "business_phone": nz(businessPhone).map(AnyCodable.init),
      "business_address": nz(businessAddress).map(AnyCodable.init),
      "business_logo_url": nz(businessLogoUrl).map(AnyCodable.init),
      "business_email": nz(businessEmail).map(AnyCodable.init),
      "bank_account_number": nz(bankAccountNumber).map(AnyCodable.init),
      "bank_account_name": nz(bankAccountName).map(AnyCodable.init),
      "bank_name": nz(bankName).map(AnyCodable.init)
    ]
    let body = raw.compactMapValues { $0 }

    let response = try await client
      .from("users")
      .upsert(body, onConflict: "id")
      .select()
      .single()
      .execute()

    return try JSONDecoder().decode(UserRecord.self, from: response.data)
  }

  func fetchAllUsers(limit: Int? = nil, offset: Int? = nil) async throws -> [UserRecord] {
    if let limit, let offset {
      let response = try await client
        .from("users")
        .select()
        .range(from: offset, to: offset + limit - 1)
        .execute()
      return try JSONDecoder().decode([UserRecord].self, from: response.data)
    } else if let limit {
      let response = try await client
        .from("users")
        .select()
        .limit(limit)
        .execute()
      return try JSONDecoder().decode([UserRecord].self, from: response.data)
    } else {
      let response = try await client
        .from("users")
        .select()
        .execute()
      return try JSONDecoder().decode([UserRecord].self, from: response.data)
    }
  }
}

