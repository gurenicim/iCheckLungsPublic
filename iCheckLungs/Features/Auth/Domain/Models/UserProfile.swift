//
//  UserProfile.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation

struct UserProfile: Equatable {
    let uid: String
    let email: String?
    let displayName: String?
    let plan: UserPlan
    let createdAt: Date
    let scansRemaining: Int
    let scansLimit: Int
    let subscriptionPeriodEnd: Date?
    let trialUsed: Bool
}

enum UserPlan: String {
    case none    = "none"
    case weekly  = "weekly"
    case monthly = "monthly"
    // Legacy values — kept for backward compatibility with existing Firestore docs
    case free = "free"
    case pro  = "pro"

    var displayName: String {
        switch self {
        case .none, .free: return "No active plan"
        case .weekly:      return "Weekly"
        case .monthly:     return "Monthly"
        case .pro:         return "Pro"
        }
    }

    var isActive: Bool {
        switch self {
        case .weekly, .monthly, .pro: return true
        case .none, .free:            return false
        }
    }

    var scansLimit: Int {
        switch self {
        case .weekly:           return 5
        case .monthly, .pro:    return 20
        case .none, .free:      return 0
        }
    }
}

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated(UserProfile)
}
