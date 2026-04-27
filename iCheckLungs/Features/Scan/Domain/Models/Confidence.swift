//
//  Confidence.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

enum Confidence: String, Decodable {
    case high
    case medium
    case low
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self).lowercased()
        self = Confidence(rawValue: raw) ?? .unknown
    }
}
