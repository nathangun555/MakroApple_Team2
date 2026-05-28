//
//  SupabaseManager.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 15/10/25.
//

import Foundation
import Supabase

final class SupabaseManager {
  static let shared = SupabaseManager()

  private let supabaseURL = URL(string: "https://hddpofvkwanymugjtlpp.supabase.co")!
  private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhkZHBvZnZrd2FueW11Z2p0bHBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3ODczMTIsImV4cCI6MjA4MzM2MzMxMn0.47Ts6UPaoQHQhrQ2nVx8LnTxFuJxdjZUXbr0mkLw9cA"

  let client: SupabaseClient

  private init() {
    client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
  }
    
    var currentUser: User? {
           client.auth.currentUser
       }
}

