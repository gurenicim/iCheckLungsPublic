//
//  SignInWithEmailUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

final class SignInWithEmailUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> UserProfile {
        try await repository.signIn(email: email, password: password)
    }
}
