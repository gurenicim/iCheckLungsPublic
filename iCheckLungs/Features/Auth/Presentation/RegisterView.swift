//
//  RegisterView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var viewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                form

                registerButton
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
            Text("Create account")
                .font(.title.bold())
            Text("Start analyzing chest X-rays with AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var form: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(passwordMismatch
                    ? Color.red.opacity(0.1)
                    : Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

            if passwordMismatch {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var registerButton: some View {
        Button(action: {
            Task { await viewModel.register(email: email, password: password) }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white).padding(.trailing, 4)
                }
                Text("Create Account")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid && !viewModel.isLoading ? Color.blue : Color.blue.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!isFormValid || viewModel.isLoading)
    }

    private var isFormValid: Bool {
        !email.isEmpty && password.count >= 6 && password == confirmPassword
    }
}

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
