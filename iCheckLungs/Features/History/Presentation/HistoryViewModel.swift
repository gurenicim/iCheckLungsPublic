//
//  HistoryViewModel.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import SwiftUI
import Combine

@MainActor final class HistoryViewModel: ObservableObject {
    @Published var items: [ScanHistoryItem] = []

    /// Emits (scanId, userId) when the Firestore listener sees a pending scan flip to .done.
    /// ScanViewModel subscribes to this as an FCM fallback.
    let scanCompletedPublisher = PassthroughSubject<(scanId: String, userId: String), Never>()

    private let observeHistoryUseCase: ObserveHistoryUseCase
    private let historyRepository: HistoryRepository
    private var listenerHandle: HistoryListenerHandle?
    private var currentUserId: String?

    init(observeHistoryUseCase: ObserveHistoryUseCase, historyRepository: HistoryRepository) {
        self.observeHistoryUseCase = observeHistoryUseCase
        self.historyRepository = historyRepository
    }

    func delete(_ item: ScanHistoryItem) {
        guard let userId = currentUserId else { return }
        Task {
            try? await historyRepository.deleteScan(userId: userId, scanId: item.id)
        }
    }

    func startListening(userId: String) {
        currentUserId = userId
        listenerHandle?.remove()
        listenerHandle = observeHistoryUseCase.execute(userId: userId) { [weak self] updatedItems in
            Task { @MainActor [weak self] in
                guard let self else { return }

                // Mark stale pending jobs as failed (pending > 15 min, not the current active job)
                let pendingScanId = UserDefaults.standard.string(forKey: "pendingScanId")
                let staleThreshold = Date().addingTimeInterval(-15 * 60)
                let cleaned = updatedItems.map { item -> ScanHistoryItem in
                    guard item.status == .pending,
                          item.id != pendingScanId,
                          item.createdAt < staleThreshold
                    else { return item }
                    return ScanHistoryItem(
                        id: item.id,
                        userId: item.userId,
                        status: .failed,
                        findings: item.findings,
                        confidence: item.confidence,
                        createdAt: item.createdAt,
                        completedAt: item.completedAt
                    )
                }
                self.items = cleaned

                // FCM fallback: if the tracked pending scan flipped to done, notify ScanViewModel
                if let pendingScanId,
                   let doneItem = cleaned.first(where: { $0.id == pendingScanId && $0.status == .done }) {
                    self.scanCompletedPublisher.send((scanId: doneItem.id, userId: userId))
                }
            }
        }
    }

    func stopListening() {
        listenerHandle?.remove()
        listenerHandle = nil
    }
}
