//
//  ObserveHistoryUseCase.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

final class ObserveHistoryUseCase {
    private let repository: HistoryRepository

    init(repository: HistoryRepository) {
        self.repository = repository
    }

    func execute(userId: String, onUpdate: @escaping ([ScanHistoryItem]) -> Void) -> HistoryListenerHandle {
        repository.observeScans(userId: userId, onUpdate: onUpdate)
    }
}
