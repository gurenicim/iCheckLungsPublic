//
//  FCMService.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import Combine
import UIKit

struct FCMPayload {
    let type: String
    let scanId: String
    let userId: String
}

final class FCMService: NSObject {
    static let shared = FCMService()
    private let logger = AppLogger(category: .notifications)

    private let payloadSubject = PassthroughSubject<FCMPayload, Never>()
    var payloadPublisher: AnyPublisher<FCMPayload, Never> { payloadSubject.eraseToAnyPublisher() }

    private override init() {
        super.init()
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            logger.info("Notification permission granted: \(granted)")
            return granted
        } catch {
            logger.error("Notification permission request failed", error: error)
            return false
        }
    }

    func registerForRemoteNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func handleIncomingData(_ userInfo: [AnyHashable: Any]) {
        guard
            let type = userInfo["type"] as? String,
            let scanId = userInfo["scanId"] as? String,
            let userId = userInfo["userId"] as? String
        else {
            logger.warning("Received FCM message with unexpected payload: \(userInfo)")
            return
        }

        logger.info("Received FCM payload: type=\(type) scanId=\(scanId)")
        let payload = FCMPayload(type: type, scanId: scanId, userId: userId)
        payloadSubject.send(payload)
    }
}

extension FCMService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        logger.info("FCM token refreshed: \(token.prefix(20))...")
        NotificationCenter.default.post(
            name: .fcmTokenRefreshed,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("FCMTokenRefreshed")
}
