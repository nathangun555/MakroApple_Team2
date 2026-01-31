//
//  AuthenticationView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 31/01/26.
//


//
//  AuthenticationView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 31/01/26.
//

import SwiftUI
import AuthenticationServices
import Supabase

struct AuthenticationView: View {
    @EnvironmentObject var session: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // App Icon
                    if let appIcon = Bundle.main.icon {
                        Image(uiImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(22)
                    }
                    
                    Text("Login to Your Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 8)
                    
                    // Email Field
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                    
                    // Sign In Button
                    Button(action: handleEmailSignIn) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign in")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 50)
                    .background(email.isEmpty || password.isEmpty ? Color.gray : Color(UIColor.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or sign in with")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    // Sign In with Apple Button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        Button("Sign up") {
                            showSignUp = true
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
    
    // MARK: - Email/Password Sign In
    private func handleEmailSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                let userId = response.user.id
                
                // Check if user exists in database
                let existingUser: UserRecord? = try? await SupabaseManager.shared.client
                    .from("users")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .single()
                    .execute()
                    .value
                
                if existingUser == nil {
                    // Create user record if not exists
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
                }
                
                await MainActor.run {
                    session.userId = userId.uuidString
                    session.isSignedIn = true
                }
                
                print("✅ Signed in: \(email)")
                
            } catch {
                await MainActor.run {
                    errorMessage = "Login failed: \(error.localizedDescription)"
                }
                print("❌ Sign in error: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // MARK: - Apple Sign In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
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
                    
                    let userId = response.user.id
                    let email = response.user.email ?? appleID.email ?? ""
                    
                    let existingUser: UserRecord? = try? await SupabaseManager.shared.client
                        .from("users")
                        .select()
                        .eq("id", value: userId.uuidString)
                        .single()
                        .execute()
                        .value
                    
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
                    }
                    
                    await MainActor.run {
                        session.userId = userId.uuidString
                        session.isSignedIn = true
                    }
                    
                    print("✅ Apple Sign In: \(session.userId ?? "Unknown")")
                    
                } catch {
                    await MainActor.run {
                        errorMessage = "Apple sign in failed: \(error.localizedDescription)"
                    }
                    print("❌ Apple sign in error: \(error)")
                }
                
                await MainActor.run {
                    isLoading = false
                }
            }
            
        case .failure(let error):
            errorMessage = "Sign in cancelled: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Struct
private struct MinimalUserInsert: Encodable {
    let id: String
    let email: String
    let is_active: Bool
    let created_at: String
}

//// Extension for Bundle Icon (if not already exists)
//extension Bundle {
//    var icon: UIImage? {
//        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
//           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
//           let files = primary["CFBundleIconFiles"] as? [String],
//           let last = files.last {
//            return UIImage(named: last)
//        }
//        return nil
//    }
//}
