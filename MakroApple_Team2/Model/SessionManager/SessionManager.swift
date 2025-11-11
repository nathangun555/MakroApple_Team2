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
        #if DEBUG
        if useDevMode {
            setupDevSession()
            return  // Skip auth listener in dev mode
        }
        #endif
        
        startAuthListener()
    }
    
    // ✅ Dev mode setup - instant, synchronous
    private func setupDevSession() {
        self.isSignedIn = true
        self.userId = "11a1686a-f25c-4f0d-bc6b-1327fe8eca63"
        print("🧪 DEV MODE: Instant session loaded")
        print("🪪 userId:", userId ?? "nil")
    }
    
    // Production: restore session from Supabase
    func restoreSessionIfAvailable() async {
        #if DEBUG
        if useDevMode {
            print("🧪 DEV MODE: Skipping Supabase auth")
            return
        }
        #endif
        
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
        #if DEBUG
        if useDevMode {
            print("🧪 DEV MODE: Auth listener disabled")
            return
        }
        #endif
        
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
        #if DEBUG
        if useDevMode {
            print("🧪 DEV MODE: Sign out disabled")
            return
        }
        #endif
        
        do { try await SupabaseManager.shared.client.auth.signOut() } catch { }
        isSignedIn = false
        userId = nil
    }
}
