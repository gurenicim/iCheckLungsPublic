//
//  ScanRequest.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation

struct ScanRequest {
    let imageData: Data
    let query: String
    let scanId: String
    let userId: String

    init(imageData: Data, query: String, userId: String) {
        self.imageData = imageData
        self.query = query
        self.scanId = UUID().uuidString
        self.userId = userId
    }
}
