//
//  SignUpView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 31/01/26.
//

//
//  SignUpView.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 31/01/26.
//

import SwiftUI
import Supabase

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
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
                
                Text("Create Your Account")
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
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                
                // Confirm Password Field
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                
                // Password Requirements
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password must:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("• Be at least 6 characters")
                        .font(.caption)
                        .foregroundColor(password.count >= 6 ? .green : .gray)
                    Text("• Match confirmation")
                        .font(.caption)
                        .foregroundColor(!password.isEmpty && password == confirmPassword ? .green : .gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                
                // Sign Up Button
                Button(action: handleSignUp) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign up")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(isFormValid ? Color(UIColor.systemBlue) : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .disabled(!isFormValid || isLoading)
                
                // Error or Success Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let success = successMessage {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Back to Login Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    Button("Sign in") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .font(.subheadline)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func handleSignUp() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // Sign up user
                let response = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password
                )
                
                let userId = response.user.id
                
                // Create user record in database
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
                
                await MainActor.run {
                    session.userId = userId.uuidString
                    session.isSignedIn = true
                    successMessage = "Account created successfully!"
                }
                
                print("✅ Account created: \(email)")
                
                // Auto dismiss after 1 second
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Sign up failed: \(error.localizedDescription)"
                }
                print("❌ Sign up error: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// Helper struct
private struct MinimalUserInsert: Encodable {
    let id: String
    let email: String
    let is_active: Bool
    let created_at: String
}
