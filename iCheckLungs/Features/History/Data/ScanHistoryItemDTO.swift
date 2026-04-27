//
//  ScanHistoryItemDTO.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import FirebaseFirestore

struct ScanHistoryItemDTO {
    let id: String
    let status: String
    let findings: String?
    let confidence: String?
    let createdAt: Timestamp?
    let completedAt: Timestamp?

    init?(id: String, data: [String: Any]) {
        self.id = id
        guard let status = data["status"] as? String else { return nil }
        self.status = status
        self.findings = data["findings"] as? String
        self.confidence = data["confidence"] as? String
        self.createdAt = data["createdAt"] as? Timestamp
        self.completedAt = data["completedAt"] as? Timestamp
    }

    func toDomain(userId: String) -> ScanHistoryItem {
        ScanHistoryItem(
            id: id,
            userId: userId,
            status: ScanJobStatus(rawValue: status) ?? .pending,
            findings: findings,
            confidence: confidence.flatMap { Confidence(rawValue: $0.lowercased()) },
            createdAt: createdAt?.dateValue() ?? Date(),
            completedAt: completedAt?.dateValue()
        )
    }
}
