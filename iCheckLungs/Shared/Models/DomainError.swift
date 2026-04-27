//
//  DomainError.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation

enum DomainError: Error, LocalizedError, Equatable {
    case networkError(String)
    case decodingError
    case unauthorized
    case serverError(Int)
    case unknown
    case authError(String)
    case storageUploadFailed(String)
    case jobNotFound
    case scanFailed(String)
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .networkError(let message):      return "Network error: \(message)"
        case .decodingError:                  return "Failed to parse server response."
        case .unauthorized:                   return "Unauthorized. Please sign in again."
        case .serverError(let code):          return "Server error (\(code))."
        case .unknown:                        return "An unexpected error occurred."
        case .authError(let message):         return "Authentication error: \(message)"
        case .storageUploadFailed(let msg):   return "Upload failed: \(msg)"
        case .jobNotFound:                    return "Scan result not found."
        case .scanFailed(let message):        return "Scan failed: \(message)"
        case .quotaExceeded:                  return "You've reached your scan limit. Upgrade to Pro for unlimited scans."
        }
    }
}
