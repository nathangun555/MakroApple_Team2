////
////  SignInWithAppleView.swift
////  MakroApple_Team2
////
////  Created by Nathan Gunawan on 06/10/25.
////
//
//import SwiftUI
//import AuthenticationServices
//import Supabase
//
//struct SignInWithAppleView: View {
//    @EnvironmentObject var session: SessionManager   // ✅ Shared session
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack(spacing: 30) {
//            Spacer()
//
//            Text("Selamat Datang di MakroApple")
//                .font(.title2)
//                .fontWeight(.semibold)
//
//            if isLoading {
//                ProgressView("Sedang masuk...")
//            } else {
//                SignInWithAppleButton(.signIn) { request in
//                    request.requestedScopes = [.fullName, .email]
//                } onCompletion: { result in
//                    handleSignIn(result: result)
//                }
//                .frame(height: 55)
//                .padding(.horizontal, 40)
//            }
//
//            if let error = errorMessage {
//                Text(error)
//                    .foregroundColor(.red)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//            }
//
//            Spacer()
//        }
//    }
//
//    private func handleSignIn(result: Result<ASAuthorization, Error>) {
//        switch result {
//        case .success(let auth):
//            isLoading = true
//            Task {
//                do {
//                    guard let appleID = auth.credential as? ASAuthorizationAppleIDCredential,
//                          let tokenData = appleID.identityToken,
//                          let token = String(data: tokenData, encoding: .utf8)
//                    else {
//                        throw URLError(.badServerResponse)
//                    }
//
//                    // Authenticate with Supabase
//                    let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
//                        credentials: .init(provider: .apple, idToken: token)
//                    )
//
//                    // ✅ Store user info globally
//                    await MainActor.run {
//                        session.userId = response.user.id.uuidString
//                        session.isSignedIn = true
//                    }
//
//                    print("✅ Signed in as: \(session.userId ?? "Unknown")")
//
//                } catch {
//                    await MainActor.run {
//                        errorMessage = error.localizedDescription
//                    }
//                }
//
//                await MainActor.run {
//                    isLoading = false
//                }
//            }
//
//        case .failure(let error):
//            errorMessage = error.localizedDescription
//        }
//    }
//}


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

                    let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: token)
                    )

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
