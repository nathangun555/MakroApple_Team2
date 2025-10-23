//
//  SignInWithAppleView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI
import AuthenticationServices
import Supabase

struct SignInWithAppleView: View {
    @EnvironmentObject var session: SessionManager   // ✅ Shared session
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Selamat Datang di MakroApple")
                .font(.title2)
                .fontWeight(.semibold)

            if isLoading {
                ProgressView("Sedang masuk...")
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleSignIn(result: result)
                }
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

                    // Authenticate with Supabase
                    let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: token)
                    )

                    // ✅ Store user info globally
                    await MainActor.run {
                        session.userId = response.user.id.uuidString
                        session.isSignedIn = true
                    }

                    print("✅ Signed in as: \(session.userId ?? "Unknown")")

                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }

                await MainActor.run {
                    isLoading = false
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

