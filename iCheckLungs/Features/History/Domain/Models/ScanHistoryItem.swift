//
//  ScanHistoryItem.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation

struct ScanHistoryItem: Identifiable, Equatable {
    let id: String             // scanId
    let userId: String
    let status: ScanJobStatus
    let findings: String?      // nil when still pending
    let confidence: Confidence?
    let createdAt: Date
    let completedAt: Date?

    /// Converts to ScanResult for display in ResultsView. Returns nil if scan is not done.
    func toScanResult() -> ScanResult? {
        guard let findings else { return nil }
        return ScanResult(
            scanId: id,
            userId: userId,
            findings: findings,
            confidence: confidence ?? .unknown,
            rawOutput: "",
            timestamp: completedAt ?? createdAt
        )
    }
}
