//
//  ScanResult.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation

struct ScanResult: Equatable {
    let scanId: String
    let userId: String
    let findings: String
    let confidence: Confidence
    let rawOutput: String
    let timestamp: Date
}
