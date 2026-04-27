//
//  HistoryRepository.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

protocol HistoryRepository {
    func observeScans(userId: String, onUpdate: @escaping ([ScanHistoryItem]) -> Void) -> HistoryListenerHandle
    func deleteScan(userId: String, scanId: String) async throws
}

protocol HistoryListenerHandle {
    func remove()
}
