//
//  AppCheckProviderFactory.swift
//  iCheckLungs
//
//  Created by Guren Icim on 25.03.2026.
//

import Foundation
import FirebaseCore
import FirebaseAppCheck

final class CloneAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    private let logger = AppLogger(category: .firebase)

    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // debug provider for development
        return AppCheckDebugProvider(app: app)
        #else
        // use app attest for production
        return AppAttestProvider(app: app)
        #endif
    }
}
