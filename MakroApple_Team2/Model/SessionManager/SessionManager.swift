//
//  SessionManager.swift
//

import Foundation
import Supabase
import Combine
import SwiftUI

@MainActor
final class SessionManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userId: String? = nil
    
    private var authListenerTask: Task<Void, Never>? = nil
    
    // ✅ Add dev mode flag
    private let useDevMode = true  // Set to false for production
    
    init() {
        // ✅ Immediate dev session
        if useDevMode {
            setupDevSession()
            return  // Skip auth listener in dev mode
        }
        
        startAuthListener()
    }
    
    // ✅ Dev mode setup - instant, synchronous
    private func setupDevSession() {
        self.isSignedIn = true
//        self.userId = "ffb3ac4f-3b74-418b-938b-f02175804dc7" // new
        self.userId = "ec7eea39-e2b6-4e46-b847-646019276f67" // has template
//        self.userId = "f4c00649-2639-4d1f-84c3-aff5f8f4d781" // nathan menu
        print("🧪 DEV MODE: Instant session loaded")
        print("🪪 userId:", userId ?? "nil")
    }
    
    // Production: restore session from Supabase
    func restoreSessionIfAvailable() async {
        if useDevMode {
            print("🧪 DEV MODE: Skipping Supabase auth")
            return
        }
        
        do {
            if let current = try? await SupabaseManager.shared.client.auth.currentSession {
                isSignedIn = true
                userId = current.user.id.uuidString
                return
            }
            let session = try await SupabaseManager.shared.client.auth.session
            isSignedIn = true
            userId = session.user.id.uuidString
        } catch {
            isSignedIn = false
            userId = nil
        }
    }
    
    // Production: listen for auth changes
    func startAuthListener() {
        if useDevMode {
            print("🧪 DEV MODE: Auth listener disabled")
            return
        }
        
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
        if useDevMode {
            print("🧪 DEV MODE: Sign out disabled")
            return
        }
        
        do { try await SupabaseManager.shared.client.auth.signOut() } catch { }
        isSignedIn = false
        userId = nil
    }
}
