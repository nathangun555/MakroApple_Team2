//
//  SessionManager.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 20/10/25.
//

// SessionManager.swift
//import Foundation
//import SwiftUI
//import Combine
//
//final class SessionManager: ObservableObject {
//    @Published var userId: String?
//    @Published var isSignedIn = false
//}
//



import Foundation
import Supabase
import Combine
import SwiftUI


@MainActor
final class SessionManager: ObservableObject {
  @Published var isSignedIn: Bool = false
  @Published var userId: String? = nil

  // Keep a reference so the listener isn't deallocated
  private var authListenerTask: Task<Void, Never>? = nil

  init() {
    // Optionally start the auth listener immediately
    startAuthListener()
  }

  // Call on app launch (e.g., in App .task) to load any existing session
  func restoreSessionIfAvailable() async {
    do {
      // Prefer currentSession if available, otherwise session
      if let current = try? await SupabaseManager.shared.client.auth.currentSession {
        isSignedIn = true
        userId = current.user.id.uuidString
        return
      }
      // Fallback to non-optional session API
      let session = try await SupabaseManager.shared.client.auth.session
      isSignedIn = true
      userId = session.user.id.uuidString
    } catch {
      isSignedIn = false
      userId = nil
    }
  }

  // Live updates when user signs in/out or tokens refresh
  func startAuthListener() {
    authListenerTask?.cancel()
    authListenerTask = Task { [weak self] in
      guard let self else { return }
      for await state in SupabaseManager.shared.client.auth.authStateChanges {
        if let session = state.session {
          await MainActor.run {
            self.isSignedIn = true
            self.userId = session.user.id.uuidString
          }
        } else {
          await MainActor.run {
            self.isSignedIn = false
            self.userId = nil
          }
        }
      }
    }
  }

  func stopAuthListener() {
    authListenerTask?.cancel()
    authListenerTask = nil
  }

  func signOut() async {
    do { try await SupabaseManager.shared.client.auth.signOut() } catch { }
    isSignedIn = false
    userId = nil
  }
}
