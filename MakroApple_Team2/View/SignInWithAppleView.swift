import SwiftUI
import AuthenticationServices
import Supabase

struct SignInWithAppleView: View {
    @EnvironmentObject var session: SessionManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Coba ambil App Icon langsung dari bundle
            if let appIcon = Bundle.main.icon {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }

            if isLoading {
                ProgressView("Sedang masuk...")
                    .padding(.top, 8)
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 55)
                .padding(.horizontal, 40)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
    
    // Helper struct untuk insert user baru
    private struct MinimalUserInsert: Encodable {
        let id: String
        let email: String
        let is_active: Bool
        let created_at: String
    }

    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            isLoading = true
            Task {
                do {
                    guard let appleID = auth.credential as? ASAuthorizationAppleIDCredential,
                          let tokenData = appleID.identityToken,
                          let token = String(data: tokenData, encoding: .utf8)
                    else {
                        throw URLError(.badServerResponse)
                    }

                    // Sign in dengan Apple
                    let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: token)
                    )

                    let userId = response.user.id
                    let email = response.user.email ?? appleID.email ?? ""
                    
                    // Check apakah user sudah ada di database
                    let existingUser: UserRecord? = try? await SupabaseManager.shared.client
                        .from("users")
                        .select()
                        .eq("id", value: userId.uuidString)
                        .single()
                        .execute()
                        .value
                    
                    // Jika user baru, insert ke database dengan data minimal
                    if existingUser == nil {
                        let newUser = MinimalUserInsert(
                            id: userId.uuidString,
                            email: email,
                            is_active: true,
                            created_at: ISO8601DateFormatter().string(from: Date())
                        )
                        
                        try await SupabaseManager.shared.client
                            .from("users")
                            .insert(newUser)
                            .execute()
                        
                        print("✅ New user created in database: \(userId)")
                    } else {
                        print("✅ Existing user found: \(userId)")
                    }

                    // Set session
                    await MainActor.run {
                        session.userId = userId.uuidString
                        session.isSignedIn = true
                    }

                    print("✅ Signed in as: \(session.userId ?? "Unknown")")

                } catch {
                    await MainActor.run {
                        errorMessage = "Login gagal: \(error.localizedDescription)"
                    }
                    print("❌ Sign in error: \(error)")
                }

                await MainActor.run {
                    isLoading = false
                }
            }

        case .failure(let error):
            errorMessage = "Login dibatalkan: \(error.localizedDescription)"
        }
    }
}

import UIKit

extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last {
            return UIImage(named: last)
        }
        return nil
    }
}
