//
//  SignInWithGoogleUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

final class SignInWithGoogleUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(idToken: String, accessToken: String) async throws -> UserProfile {
        try await repository.signInWithGoogle(idToken: idToken, accessToken: accessToken)
    }
}
