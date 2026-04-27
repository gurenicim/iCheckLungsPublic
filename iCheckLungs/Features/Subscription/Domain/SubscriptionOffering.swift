//
//  SubscriptionOffering.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import Foundation

struct SubscriptionOffering: Identifiable, Equatable {
    let id: String           // e.g. "weekly" or "monthly"
    let displayName: String
    let priceString: String  // e.g. "$2.99/week"
    let scansPerPeriod: Int
    let period: SubscriptionPeriod
}

enum SubscriptionPeriod: String {
    case weekly  = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .weekly:  return "week"
        case .monthly: return "month"
        }
    }
}
