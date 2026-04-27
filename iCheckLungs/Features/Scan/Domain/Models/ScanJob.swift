//
//  ScanJob.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation

struct ScanJob: Equatable {
    let scanId: String
    let userId: String
    let status: ScanJobStatus
    let createdAt: Date
}

enum ScanJobStatus: String, Equatable {
    case pending    = "pending"
    case processing = "processing"
    case done       = "done"
    case failed     = "failed"
}
