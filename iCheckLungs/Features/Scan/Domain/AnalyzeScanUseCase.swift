//
//  AnalyzeScanUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

final class AnalyzeScanUseCase {
    private let repository: ScanRepository

    init(repository: ScanRepository) {
        self.repository = repository
    }

    func execute(_ request: ScanRequest) async throws -> ScanJob {
        try await repository.submitScan(request)
    }
}
