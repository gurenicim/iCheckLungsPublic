//
//  FetchScanResultUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

final class FetchScanResultUseCase {
    private let repository: ScanRepository

    init(repository: ScanRepository) {
        self.repository = repository
    }

    func execute(userId: String, scanId: String) async throws -> ScanResult {
        try await repository.fetchResult(userId: userId, scanId: scanId)
    }
}
