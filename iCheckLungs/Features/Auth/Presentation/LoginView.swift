//
//  LoginView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var currentNonce: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                emailPasswordForm

                signInButton

                divider

                appleSignInButton

                googleSignInButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
        .if(viewModel.error != nil) { view in
            view.overlay(alignment: .top) {
                if let error = viewModel.error {
                    ErrorBanner(error: error) { viewModel.error = nil }
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.error != nil)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("Welcome back")
                .font(.title.bold())
            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var emailPasswordForm: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }

    private var signInButton: some View {
        Button(action: {
            Task { await viewModel.signIn(email: email, password: password) }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white).padding(.trailing, 4)
                }
                Text("Sign In")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isLoading ? Color.blue.opacity(0.6) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
    }

    private var divider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(Color(.separator))
            Text("or")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            Rectangle().frame(height: 1).foregroundColor(Color(.separator))
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            currentNonce = viewModel.appleSignInNonce()
            request.requestedScopes = [.fullName, .email]
            request.nonce = currentNonce
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                Task { await viewModel.signInWithApple(credential: credential) }
            case .failure(let error):
                viewModel.error = .authError(error.localizedDescription)
            }
        }
        .frame(height: 50)
        .cornerRadius(14)
        .disabled(viewModel.isLoading)
    }

    private var googleSignInButton: some View {
        Button(action: {
            Task { await viewModel.signInWithGoogle() }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.title3)
                Text("Sign in with Google")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundColor(.primary)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - View extension helper

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
