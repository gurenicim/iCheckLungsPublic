//
//  StorageService.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    private let logger = AppLogger(category: .firebase)

    private init() {}

    func uploadScanImage(uid: String, scanId: String, imageData: Data) async throws -> String {
        let path = AppConstants.Storage.scanImagePath(uid: uid, scanId: scanId)
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        logger.info("Uploading scan image to: \(path)")
        do {
            _ = try await ref.putDataAsync(imageData, metadata: metadata)
        } catch {
            logger.error("Upload failed for scanId: \(scanId)", error: error)
            throw DomainError.storageUploadFailed(error.localizedDescription)
        }
        logger.info("Upload complete for scanId: \(scanId)")

        return "gs://\(storage.reference().bucket)/\(path)"
    }

    func fetchDownloadURL(uid: String, scanId: String) async throws -> URL {
        let path = AppConstants.Storage.scanImagePath(uid: uid, scanId: scanId)
        return try await storage.reference().child(path).downloadURL()
    }

    func deleteScanImage(uid: String, scanId: String) async throws {
        let path = AppConstants.Storage.scanImagePath(uid: uid, scanId: scanId)
        try await storage.reference().child(path).delete()
        logger.info("Deleted scan image: \(path)")
    }
}
