//
//  AppConstants.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

enum AppConstants {
    enum API {
        static let baseURL = "http://kwk48cg8gws44osk0wosssc0.217.154.80.168.sslip.io"
        static let analyzePath = "/analyze"
    }

    enum Firestore {
        static let usersCollection = "users"
        static let scansSubcollection = "scans"
    }

    enum Storage {
        static func scanImagePath(uid: String, scanId: String) -> String {
            "users/\(uid)/scans/\(scanId)/image.jpg"
        }
    }
}
