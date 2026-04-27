//
//  NotificationRouter.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//
//  Routes FCM payloads received at launch or via tap to the ScanViewModel.
//

import Foundation

final class NotificationRouter {
    static let shared = NotificationRouter()

    // Stored when app launches from a terminated state via a notification tap.
    private(set) var pendingLaunchPayload: FCMPayload?

    private init() {}

    func storeLaunchPayload(_ userInfo: [AnyHashable: Any]) {
        guard
            let type = userInfo["type"] as? String,
            let scanId = userInfo["scanId"] as? String,
            let userId = userInfo["userId"] as? String
        else { return }
        pendingLaunchPayload = FCMPayload(type: type, scanId: scanId, userId: userId)
    }

    func consumeLaunchPayload() -> FCMPayload? {
        let payload = pendingLaunchPayload
        pendingLaunchPayload = nil
        return payload
    }
}
