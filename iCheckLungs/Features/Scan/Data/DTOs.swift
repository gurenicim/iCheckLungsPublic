//
//  DTOs.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Submit job response (POST /analyze)

struct SubmitJobResponseDTO: Decodable {
    let jobId: String

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
    }
}

// MARK: - Scan result record from Firestore

struct ScanRecordDTO {
    let scanId: String
    let status: String
    let findings: String?
    let confidence: String?
    let rawOutput: String?
    let createdAt: Timestamp?
    let completedAt: Timestamp?

    init?(scanId: String, data: [String: Any]) {
        self.scanId = scanId
        guard let status = data["status"] as? String else { return nil }
        self.status = status
        self.findings = data["findings"] as? String
        self.confidence = data["confidence"] as? String
        self.rawOutput = data["raw_output"] as? String
        self.createdAt = data["createdAt"] as? Timestamp
        self.completedAt = data["completedAt"] as? Timestamp
    }

    func toDomain(userId: String) -> ScanResult? {
        guard
            status == "done",
            let findings,
            let confidence
        else { return nil }

        return ScanResult(
            scanId: scanId,
            userId: userId,
            findings: findings,
            confidence: Confidence(rawValue: confidence.lowercased()) ?? .unknown,
            rawOutput: rawOutput ?? "",
            timestamp: completedAt?.dateValue() ?? createdAt?.dateValue() ?? Date()
        )
    }
}
