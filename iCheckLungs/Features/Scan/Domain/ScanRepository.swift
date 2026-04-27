//
//  ScanRepository.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

protocol ScanRepository {
    func submitScan(_ request: ScanRequest) async throws -> ScanJob
    func fetchResult(userId: String, scanId: String) async throws -> ScanResult
}
