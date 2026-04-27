//
//  ScanViewModel.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI
import Combine

enum ScanPhase {
    case idle
    case uploading
    case submitting
    case pending(scanId: String)
    case fetching(scanId: String)
    case done(ScanResult)
    case failed(DomainError)
}

@MainActor final class ScanViewModel: ObservableObject {
    @Published var scanPhase: ScanPhase = .idle
    @Published var selectedImage: UIImage?

    private let analyzeScanUseCase: AnalyzeScanUseCase
    private let fetchScanResultUseCase: FetchScanResultUseCase
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger(category: .general)

    private static let pendingScanIdKey        = "pendingScanId"
    private static let pendingUserIdKey        = "pendingUserId"
    private static let pendingSubmittedAtKey   = "pendingSubmittedAt"
    private static let staleThresholdSeconds: TimeInterval = 15 * 60

    private var hasResumed = false

    init(
        analyzeScanUseCase: AnalyzeScanUseCase,
        fetchScanResultUseCase: FetchScanResultUseCase
    ) {
        self.analyzeScanUseCase = analyzeScanUseCase
        self.fetchScanResultUseCase = fetchScanResultUseCase
        subscribeFCMPayloads()
    }

    // MARK: - Submit

    func submitScan(userProfile: UserProfile, query: String = "Analyze this chest X-ray for abnormalities") async {
        // Quota guard: allow if trial not yet used, or if subscription scans remain
        let canScan = !userProfile.trialUsed || userProfile.scansRemaining > 0
        guard canScan else {
            scanPhase = .failed(.quotaExceeded)
            return
        }

        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let userId = userProfile.uid
        scanPhase = .uploading
        let request = ScanRequest(imageData: imageData, query: query, userId: userId)

        do {
            scanPhase = .submitting
            let job = try await analyzeScanUseCase.execute(request)
            persistPendingScan(scanId: job.scanId, userId: userId)
            scanPhase = .pending(scanId: job.scanId)
            logger.info("Scan job submitted: \(job.scanId)")
        } catch let domainError as DomainError {
            scanPhase = .failed(domainError)
        } catch {
            scanPhase = .failed(.unknown)
        }
    }

    // MARK: - FCM result delivery

    func onScanComplete(scanId: String, userId: String) async {
        if case .pending(let pendingId) = scanPhase, pendingId == scanId {
        } else {
            guard let storedId = UserDefaults.standard.string(forKey: Self.pendingScanIdKey),
                  storedId == scanId else { return }
        }

        scanPhase = .fetching(scanId: scanId)
        do {
            let result = try await fetchScanResultUseCase.execute(userId: userId, scanId: scanId)
            clearPendingScan()
            scanPhase = .done(result)
        } catch let domainError as DomainError {
            scanPhase = .failed(domainError)
        } catch {
            scanPhase = .failed(.unknown)
        }
    }

    // MARK: - Resume on app relaunch

    func resumePendingScanIfNeeded() async {
        guard !hasResumed else { return }
        hasResumed = true
        guard
            let scanId = UserDefaults.standard.string(forKey: Self.pendingScanIdKey),
            let userId = UserDefaults.standard.string(forKey: Self.pendingUserIdKey)
        else { return }

        logger.info("Resuming pending scan: \(scanId)")

        // Check if result already in Firestore
        do {
            let result = try await fetchScanResultUseCase.execute(userId: userId, scanId: scanId)
            clearPendingScan()
            scanPhase = .done(result)
        } catch DomainError.jobNotFound {
            // Not done yet — only re-enter pending if the job is recent enough
            let submittedAt = UserDefaults.standard.double(forKey: Self.pendingSubmittedAtKey)
            let age = Date().timeIntervalSinceReferenceDate - submittedAt
            if submittedAt > 0, age < Self.staleThresholdSeconds {
                scanPhase = .pending(scanId: scanId)
            } else {
                // Stale job — discard it silently
                clearPendingScan()
            }
        } catch {
            // Leave in idle, don't surface stale errors on relaunch
            clearPendingScan()
        }
    }

    // MARK: - Helpers

    func clearResult() {
        scanPhase = .idle
        selectedImage = nil
    }

    var error: DomainError? {
        if case .failed(let err) = scanPhase { return err }
        return nil
    }

    var result: ScanResult? {
        if case .done(let result) = scanPhase { return result }
        return nil
    }

    var isLoading: Bool {
        switch scanPhase {
        case .uploading, .submitting, .fetching: return true
        default: return false
        }
    }

    // MARK: - FCM subscription

    private func subscribeFCMPayloads() {
        FCMService.shared.payloadPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                guard payload.type == "scan_complete" else { return }
                Task { await self?.onScanComplete(scanId: payload.scanId, userId: payload.userId) }
            }
            .store(in: &cancellables)
    }

    // MARK: - UserDefaults persistence

    private func persistPendingScan(scanId: String, userId: String) {
        UserDefaults.standard.set(scanId, forKey: Self.pendingScanIdKey)
        UserDefaults.standard.set(userId, forKey: Self.pendingUserIdKey)
        UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: Self.pendingSubmittedAtKey)
    }

    private func clearPendingScan() {
        UserDefaults.standard.removeObject(forKey: Self.pendingScanIdKey)
        UserDefaults.standard.removeObject(forKey: Self.pendingUserIdKey)
        UserDefaults.standard.removeObject(forKey: Self.pendingSubmittedAtKey)
    }
}

