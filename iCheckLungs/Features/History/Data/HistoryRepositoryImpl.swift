//
//  HistoryRepositoryImpl.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import FirebaseFirestore

final class FirestoreListenerHandle: HistoryListenerHandle {
    private let registration: ListenerRegistration
    init(_ registration: ListenerRegistration) { self.registration = registration }
    func remove() { registration.remove() }
}

final class HistoryRepositoryImpl: HistoryRepository {
    private let firestoreService: FirestoreService
    private let storageService: StorageService

    init(firestoreService: FirestoreService = .shared, storageService: StorageService = .shared) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }

    func observeScans(userId: String, onUpdate: @escaping ([ScanHistoryItem]) -> Void) -> HistoryListenerHandle {
        let registration = firestoreService.listenToScans(uid: userId) { documents in
            let items = documents.compactMap { doc -> ScanHistoryItem? in
                guard let dto = ScanHistoryItemDTO(id: doc.documentID, data: doc.data()) else { return nil }
                return dto.toDomain(userId: userId)
            }
            onUpdate(items)
        }
        return FirestoreListenerHandle(registration)
    }

    func deleteScan(userId: String, scanId: String) async throws {
        try await firestoreService.deleteScan(uid: userId, scanId: scanId)
        try? await storageService.deleteScanImage(uid: userId, scanId: scanId)
    }
}
