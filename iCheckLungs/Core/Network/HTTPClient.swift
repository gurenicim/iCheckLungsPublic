//
//  HTTPClient.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Foundation
import FirebaseAppCheck
import FirebaseAuth

protocol HTTPClient {
    func perform(_ request: URLRequest) async throws -> Data
}

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func perform(_ request: URLRequest) async throws -> Data {
        var mutableRequest = request

        // AppCheck token
        do {
            let tokenResult = try await AppCheck.appCheck().token(forcingRefresh: false)
            mutableRequest.setValue(tokenResult.token, forHTTPHeaderField: "X-Firebase-AppCheck")
        } catch {
            AppLogger(category: .networking).warning("App Check token fetch failed: \(error.localizedDescription)")
        }

        // Firebase Auth ID token
        if let currentUser = Auth.auth().currentUser {
            do {
                let idToken = try await currentUser.getIDToken()
                mutableRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            } catch {
                AppLogger(category: .networking).warning("Auth ID token fetch failed: \(error.localizedDescription)")
                throw DomainError.unauthorized
            }
        } else {
            throw DomainError.unauthorized
        }

        let (data, response) = try await session.data(for: mutableRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DomainError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401, 403:
            throw DomainError.unauthorized
        case 402:
            throw DomainError.quotaExceeded
        case 500...599:
            throw DomainError.serverError(httpResponse.statusCode)
        default:
            throw DomainError.serverError(httpResponse.statusCode)
        }
    }
}
