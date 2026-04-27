//
//  SignInWithAppleUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import AuthenticationServices

final class SignInWithAppleUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(credential: ASAuthorizationAppleIDCredential) async throws -> UserProfile {
        try await repository.signInWithApple(credential: credential)
    }
}
