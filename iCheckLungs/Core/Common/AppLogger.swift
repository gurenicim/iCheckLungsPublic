//
//  AppLogger.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation
import os.log

struct AppLogger {
    private static let subsystem = "com.guren.iCheckLungs"

    enum Category: String {
        case networking = "Networking"
        case firebase = "Firebase"
        case ui = "UI"
        case general = "General"
        case auth = "Auth"
        case notifications = "Notifications"
    }

    private let logger: Logger
    private let category: Category

    init(category: Category) {
        self.category = category
        self.logger = Logger(subsystem: AppLogger.subsystem, category: category.rawValue)
    }

    func debug(_ message: String) {
        logger.debug("\(message)")
        #if DEBUG
        print("Debug: [\(category.rawValue)] \(message)")
        #endif
    }

    func info(_ message: String) {
        logger.info("\(message)")
        #if DEBUG
        print("Info: [\(category.rawValue)] \(message)")
        #endif
    }

    func warning(_ message: String) {
        logger.warning("\(message)")
        #if DEBUG
        print("Warning: [\(category.rawValue)] \(message)")
        #endif
    }

    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            logger.error("\(message): \(error.localizedDescription)")
            #if DEBUG
            print("Error: [\(category.rawValue)] \(message): \(error.localizedDescription)")
            #endif
        } else {
            logger.error("\(message)")
            #if DEBUG
            print("Error: [\(category.rawValue)] \(message)")
            #endif
        }
    }

    func success(_ message: String) {
        logger.info("\(message)")
        #if DEBUG
        print("Success: [\(category.rawValue)] \(message)")
        #endif
    }
}
