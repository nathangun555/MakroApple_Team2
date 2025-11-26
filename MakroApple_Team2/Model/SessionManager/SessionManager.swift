////
////  SessionManager.swift
////
//
//import Foundation
//import Supabase
//import Combine
//import SwiftUI
//
//@MainActor
//final class SessionManager: ObservableObject {
//    @Published var isSignedIn: Bool = false
//    @Published var userId: String? = nil
//
//    private var authListenerTask: Task<Void, Never>? = nil
//
//    // ✅ Add dev mode flag
//    private let useDevMode = false  // Set to false for production
//
//    init() {
//        // ✅ Immediate dev session
//        if useDevMode {
//            setupDevSession()
//            return  // Skip auth listener in dev mode
//        }
//
//        startAuthListener()
//    }
//
//    // ✅ Dev mode setup - instant, synchronous
//    private func setupDevSession() {
//        self.isSignedIn = true
//        self.userId = "7a1829f4-eef2-488e-ad77-b7b3f1042d7d" // new
////        self.userId = "ec7eea39-e2b6-4e46-b847-646019276f67" // has template
////        self.userId = "f4c00649-2639-4d1f-84c3-aff5f8f4d781" // nathan menu
//
////        self.userId = "49b3ba69-293d-496c-a52c-3e4f5b57329d" // Le.Aure
////        self.userId = "bade0678-f878-4168-b605-c26e105b1936" // Petito
////        self.userId = "dbbc99ea-1746-4673-afb1-a64754ed0312" // Chaneto
//
//        print("🧪 DEV MODE: Instant session loaded")
//        print("🪪 userId:", userId ?? "nil")
//    }
//
//    // Production: restore session from Supabase
//    func restoreSessionIfAvailable() async {
//        if useDevMode {
//            print("🧪 DEV MODE: Skipping Supabase auth")
//            return
//        }
//
//        do {
//            if let current = try? await SupabaseManager.shared.client.auth.currentSession {
//                isSignedIn = true
//                userId = current.user.id.uuidString
//                return
//            }
//            let session = try await SupabaseManager.shared.client.auth.session
//            isSignedIn = true
//            userId = session.user.id.uuidString
//        } catch {
//            isSignedIn = false
//            userId = nil
//        }
//    }
//
//    // Production: listen for auth changes
//    func startAuthListener() {
//        if useDevMode {
//            print("🧪 DEV MODE: Auth listener disabled")
//            return
//        }
//
//        authListenerTask?.cancel()
//        authListenerTask = Task { [weak self] in
//            guard let self else { return }
//            for await state in SupabaseManager.shared.client.auth.authStateChanges {
//                if let session = state.session {
//                    await MainActor.run {
//                        self.isSignedIn = true
//                        self.userId = session.user.id.uuidString
//                    }
//                } else {
//                    await MainActor.run {
//                        self.isSignedIn = false
//                        self.userId = nil
//                    }
//                }
//            }
//        }
//    }
//
//    func stopAuthListener() {
//        authListenerTask?.cancel()
//        authListenerTask = nil
//    }
//
//    func signOut() async {
//        if useDevMode {
//            print("🧪 DEV MODE: Sign out disabled")
//            return
//        }
//
//        do { try await SupabaseManager.shared.client.auth.signOut() } catch { }
//        isSignedIn = false
//        userId = nil
//    }
//}


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
    @Published var isAuthLoaded: Bool = false      // ⬅️ status cek session selesai
    @Published var isInitialDataLoading: Bool = false

    private var authListenerTask: Task<Void, Never>? = nil

    // ✅ Dev mode flag
    private let useDevMode = true   // Set to true hanya kalau mau bypass login

    init() {
        if useDevMode {
            setupDevSession()
            isAuthLoaded = true
            return
        }

        startAuthListener()

        Task {
            await restoreSessionIfAvailable()
            // Setelah cek session (berhasil / gagal), tandai sudah selesai
            isAuthLoaded = true
        }
    }

    // ✅ Dev mode setup - instant, synchronous
    private func setupDevSession() {
        self.isSignedIn = true
        self.userId = "bade0678-f878-4168-b605-c26e105b1936" // new
//        self.userId = "ec7eea39-e2b6-4e46-b847-646019276f67" // has template
//        self.userId = "083dc90d-ca03-4f45-a631-06fe21fe750f" // nathan menu
        
//        self.userId = "49b3ba69-293d-496c-a52c-3e4f5b57329d" // Le.Aure
//        self.userId = "bade0678-f878-4168-b605-c26e105b1936" // Petito
//        self.userId = "dbbc99ea-1746-4673-afb1-a64754ed0312" // Chaneto
        
//        self.userId = "3bd50e0a-f14e-418a-9dcf-f84df820d192"
        
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
            // currentSession bisa nil / expired, session akan refresh kalau bisa
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

        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            print("Sign out error:", error)
        }

        isSignedIn = false
        userId = nil
    }
}
