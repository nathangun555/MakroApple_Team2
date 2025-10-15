//
//  SignInView.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 14/10/25.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 250, height: 250)
                .overlay(
                    Text("Logo")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                )
                .accessibilityLabel("App logo")
                .padding(.bottom, 36)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    // TODO: Validate the credential and start a session
                    print("Apple Sign-In success: \(auth)")
                case .failure(let error):
                    print("Apple Sign-In failed: \(error.localizedDescription)")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
    }
}

#Preview {
    SignInView()
}
