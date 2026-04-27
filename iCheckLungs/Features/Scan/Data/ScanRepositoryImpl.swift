//
//  ScanRepositoryImpl.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation

final class ScanRepositoryImpl: ScanRepository {
    private let client: HTTPClient
    private let storageService: StorageService
    private let firestoreService: FirestoreService
    private let baseURL: String
    private let logger = AppLogger(category: .networking)

    init(
        client: HTTPClient = URLSessionHTTPClient(),
        storageService: StorageService = .shared,
        firestoreService: FirestoreService = .shared,
        baseURL: String = AppConstants.API.baseURL
    ) {
        self.client = client
        self.storageService = storageService
        self.firestoreService = firestoreService
        self.baseURL = baseURL
    }

    // MARK: - Submit

    func submitScan(_ request: ScanRequest) async throws -> ScanJob {
        // 1. Upload image to Firebase Storage
        logger.info("Uploading scan image for scanId: \(request.scanId)")
        let storageUrl = try await storageService.uploadScanImage(
            uid: request.userId,
            scanId: request.scanId,
            imageData: request.imageData
        )

        // 2. Create pending Firestore document
        try await firestoreService.createPendingScan(
            uid: request.userId,
            scanId: request.scanId,
            storageUrl: storageUrl
        )

        // 3. POST to /analyze (returns immediately with job_id)
        guard let url = URL(string: "\(baseURL)\(AppConstants.API.analyzePath)") else {
            throw DomainError.networkError("Invalid base URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "storageUrl": storageUrl,
            "scanId": request.scanId,
            "userId": request.userId
        ]
        urlRequest.httpBody = try JSONEncoder().encode(body)

        do {
            let data = try await client.perform(urlRequest)
            _ = try JSONDecoder().decode(SubmitJobResponseDTO.self, from: data)
        } catch let error as DomainError {
            throw error
        } catch is DecodingError {
            throw DomainError.decodingError
        } catch {
            throw DomainError.networkError(error.localizedDescription)
        }

        logger.info("Scan job submitted successfully: \(request.scanId)")
        return ScanJob(
            scanId: request.scanId,
            userId: request.userId,
            status: .pending,
            createdAt: Date()
        )
    }

    // MARK: - Fetch result

    func fetchResult(userId: String, scanId: String) async throws -> ScanResult {
        let data = try await firestoreService.fetchScan(uid: userId, scanId: scanId)
        guard
            let dto = ScanRecordDTO(scanId: scanId, data: data),
            let result = dto.toDomain(userId: userId)
        else {
            throw DomainError.jobNotFound
        }
        return result
    }
}
