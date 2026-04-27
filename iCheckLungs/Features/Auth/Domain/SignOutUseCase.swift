//
//  SignOutUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

final class SignOutUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute() throws {
        try repository.signOut()
    }
}
