//
//  FirestoreService.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let logger = AppLogger(category: .firebase)

    private init() {}

    // MARK: - User Profile

    func createUserProfile(uid: String, data: [String: Any]) async throws {
        let ref = db.collection(AppConstants.Firestore.usersCollection).document(uid)
        try await ref.setData(data, merge: true)
        logger.info("Created/merged user profile for uid: \(uid)")
    }

    func fetchUserProfile(uid: String) async throws -> [String: Any]? {
        let ref = db.collection(AppConstants.Firestore.usersCollection).document(uid)
        let snapshot = try await ref.getDocument()
        return snapshot.data()
    }

    func updateFCMToken(uid: String, token: String) async throws {
        let ref = db.collection(AppConstants.Firestore.usersCollection).document(uid)
        try await ref.setData(["fcmToken": token, "updatedAt": FieldValue.serverTimestamp()], merge: true)
        logger.info("Updated FCM token for uid: \(uid)")
    }

    // MARK: - Scans

    func createPendingScan(uid: String, scanId: String, storageUrl: String) async throws {
        let ref = db
            .collection(AppConstants.Firestore.usersCollection)
            .document(uid)
            .collection(AppConstants.Firestore.scansSubcollection)
            .document(scanId)

        let data: [String: Any] = [
            "status": "pending",
            "imageUrl": storageUrl,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await ref.setData(data)
        logger.info("Created pending scan doc: \(scanId) for uid: \(uid)")
    }

    func fetchScan(uid: String, scanId: String) async throws -> [String: Any] {
        let ref = db
            .collection(AppConstants.Firestore.usersCollection)
            .document(uid)
            .collection(AppConstants.Firestore.scansSubcollection)
            .document(scanId)

        let snapshot = try await ref.getDocument()
        guard let data = snapshot.data() else {
            throw DomainError.jobNotFound
        }
        return data
    }

    func deleteScan(uid: String, scanId: String) async throws {
        let ref = db
            .collection(AppConstants.Firestore.usersCollection)
            .document(uid)
            .collection(AppConstants.Firestore.scansSubcollection)
            .document(scanId)
        try await ref.delete()
        logger.info("Deleted scan doc: \(scanId) for uid: \(uid)")
    }

    func listenToScans(uid: String, onUpdate: @escaping ([QueryDocumentSnapshot]) -> Void) -> ListenerRegistration {
        let ref = db
            .collection(AppConstants.Firestore.usersCollection)
            .document(uid)
            .collection(AppConstants.Firestore.scansSubcollection)
            .order(by: "createdAt", descending: true)

        return ref.addSnapshotListener { snapshot, error in
            if let error {
                AppLogger(category: .firebase).error("Scan listener error", error: error)
                return
            }
            onUpdate(snapshot?.documents ?? [])
        }
    }
}
