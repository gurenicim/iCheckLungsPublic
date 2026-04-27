//
//  iCheckLungsApp.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI
import FirebaseAppCheck
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        Purchases.configure(withAPIKey: "test_VogsGVyEIlwaVGtsLxBZpHYxerp")
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        let providerFactory = CloneAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // FCM delegate
        Messaging.messaging().delegate = FCMService.shared

        // Notification center delegate for foreground display
        UNUserNotificationCenter.current().delegate = AppDelegate.notificationDelegate

        let logger = AppLogger(category: .general)
        logger.success("App initialized with Firebase, App Check and FCM")

        // Store notification payload if app was launched from a terminated state via tap
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            NotificationRouter.shared.storeLaunchPayload(userInfo)
        }

        #if DEBUG
        Task {
            do {
                let token = try await AppCheck.appCheck().token(forcingRefresh: false).token
                logger.info("App Check token obtained: \(token.prefix(20))...")
            } catch {
                logger.error("Failed to get App Check token on startup", error: error)
            }
        }
        #endif

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        AppLogger(category: .notifications).info("APNs token registered")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger(category: .notifications).error("APNs registration failed", error: error)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FCMService.shared.handleIncomingData(userInfo)
        completionHandler(.newData)
    }

    // MARK: - Static notification delegate (keeps AppDelegate clean)

    static let notificationDelegate = AppNotificationDelegate()
}

// MARK: - UNUserNotificationCenterDelegate

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let logger = AppLogger(category: .notifications)

    // Called when a notification arrives while the app is in the FOREGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        FCMService.shared.handleIncomingData(userInfo)
        // Don't show a banner; the app will react to the FCM payload directly
        completionHandler([])
    }

    // Called when the user TAPS a notification banner (foreground or background)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        logger.info("User tapped notification: \(userInfo)")
        FCMService.shared.handleIncomingData(userInfo)
        completionHandler()
    }
}

// MARK: - App

@main
struct iCheckLungsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(paywallViewModel: AppDependencies.shared.paywallViewModel)
            }
            .environmentObject(AppDependencies.shared.authViewModel)
            .environmentObject(AppDependencies.shared.scanViewModel)
            .environmentObject(AppDependencies.shared.historyViewModel)
            .onReceive(
                NotificationCenter.default.publisher(for: .fcmTokenRefreshed)
            ) { notification in
                guard let token = notification.userInfo?["token"] as? String else { return }
                Task {
                    try? await AppDependencies.shared.authRepository.updateFCMToken(token)
                }
            }
            .onReceive(
                AppDependencies.shared.authViewModel.$authState
            ) { state in
                // Identify user with RevenueCat on sign-in so purchases are linked to their Firebase UID
                if case .authenticated(let profile) = state {
                    Purchases.shared.logIn(profile.uid) { _, _, _ in }
                } else if case .unauthenticated = state {
                    Purchases.shared.logOut { _, _ in }
                }
            }
        }
    }
}
