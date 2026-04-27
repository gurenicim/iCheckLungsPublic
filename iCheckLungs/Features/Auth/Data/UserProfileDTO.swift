//
//  UserProfileDTO.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import FirebaseFirestore

struct UserProfileDTO {
    let uid: String
    let email: String?
    let displayName: String?
    let plan: String
    let createdAt: Timestamp?
    let scansRemaining: Int
    let scansLimit: Int
    let subscriptionPeriodEnd: Timestamp?
    let trialUsed: Bool

    init(uid: String, email: String?, displayName: String?, plan: String = "none", createdAt: Timestamp? = nil) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.plan = plan
        self.createdAt = createdAt
        self.scansRemaining = 0
        self.scansLimit = 0
        self.subscriptionPeriodEnd = nil
        self.trialUsed = false
    }

    init?(uid: String, data: [String: Any]) {
        self.uid = uid
        self.email = data["email"] as? String
        self.displayName = data["displayName"] as? String
        self.plan = data["plan"] as? String ?? "none"
        self.createdAt = data["createdAt"] as? Timestamp
        self.scansRemaining = data["scansRemaining"] as? Int ?? 0
        self.scansLimit = data["scansLimit"] as? Int ?? 0
        self.subscriptionPeriodEnd = data["subscriptionPeriodEnd"] as? Timestamp
        self.trialUsed = data["trialUsed"] as? Bool ?? false
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "plan": plan,
            "createdAt": FieldValue.serverTimestamp(),
            "scansRemaining": scansRemaining,
            "scansLimit": scansLimit,
            "trialUsed": trialUsed
        ]
        if let email { data["email"] = email }
        if let displayName { data["displayName"] = displayName }
        return data
    }

    func toDomain() -> UserProfile {
        UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            plan: UserPlan(rawValue: plan) ?? .none,
            createdAt: createdAt?.dateValue() ?? Date(),
            scansRemaining: scansRemaining,
            scansLimit: scansLimit,
            subscriptionPeriodEnd: subscriptionPeriodEnd?.dateValue(),
            trialUsed: trialUsed
        )
    }
}
