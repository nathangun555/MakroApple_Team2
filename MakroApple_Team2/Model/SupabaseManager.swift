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

  // Replace with your real values from Project → Settings → API
  private let supabaseURL = URL(string: "https://ynxrqdbpovgmhhoobfjt.supabase.co")!
  private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlueHJxZGJwb3ZnbWhob29iZmp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwODkwMjksImV4cCI6MjA3NTY2NTAyOX0.1da8SzP39NVbIt7gLgRbPA6wG3aDpL0es5nb-GCNfG4"

  let client: SupabaseClient

  private init() {
    client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
  }
}
