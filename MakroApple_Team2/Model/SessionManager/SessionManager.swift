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
//        self.userId = "94f7bbef-ecad-46ef-b926-7296ebd12ca3" // new
//        self.userId = "ec7eea39-e2b6-4e46-b847-646019276f67" // has template
        self.userId = "c4ed1a29-692d-4c8c-a9a5-5b74559b9629" // nathan menu
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
