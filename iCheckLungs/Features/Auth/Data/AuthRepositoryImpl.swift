//
//  AuthRepositoryImpl.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import CryptoKit

final class AuthRepositoryImpl: AuthRepository {
    private let firestoreService: FirestoreService
    private let logger = AppLogger(category: .auth)

    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.loading)
    var authStatePublisher: AnyPublisher<AuthState, Never> { authStateSubject.eraseToAnyPublisher() }

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
        listenToAuthState()
    }

    var currentUser: UserProfile? {
        if case .authenticated(let profile) = authStateSubject.value {
            return profile
        }
        return nil
    }

    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            if let firebaseUser {
                Task {
                    let profile = await self.fetchOrCreateProfile(for: firebaseUser)
                    self.authStateSubject.send(.authenticated(profile))
                }
            } else {
                authStateSubject.send(.unauthenticated)
            }
        }
    }

    private func fetchOrCreateProfile(for user: FirebaseAuth.User) async -> UserProfile {
        do {
            if let data = try await firestoreService.fetchUserProfile(uid: user.uid),
               let dto = UserProfileDTO(uid: user.uid, data: data) {
                return dto.toDomain()
            }
            let dto = UserProfileDTO(uid: user.uid, email: user.email, displayName: user.displayName)
            try await firestoreService.createUserProfile(uid: user.uid, data: dto.toFirestoreData())
            return dto.toDomain()
        } catch {
            logger.error("Failed to fetch/create user profile", error: error)
            return UserProfile(uid: user.uid, email: user.email, displayName: user.displayName, plan: .none, createdAt: Date(), scansRemaining: 0, scansLimit: 0, subscriptionPeriodEnd: nil, trialUsed: false)
        }
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return await fetchOrCreateProfile(for: result.user)
        } catch {
            throw DomainError.authError(error.localizedDescription)
        }
    }

    func register(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return await fetchOrCreateProfile(for: result.user)
        } catch {
            throw DomainError.authError(error.localizedDescription)
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> UserProfile {
        guard
            let nonce = currentNonce,
            let tokenData = credential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            throw DomainError.authError("Invalid Apple credential state.")
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        do {
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            return await fetchOrCreateProfile(for: result.user)
        } catch {
            throw DomainError.authError(error.localizedDescription)
        }
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        do {
            let result = try await Auth.auth().signIn(with: credential)
            return await fetchOrCreateProfile(for: result.user)
        } catch {
            throw DomainError.authError(error.localizedDescription)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw DomainError.authError(error.localizedDescription)
        }
    }

    func updateFCMToken(_ token: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await firestoreService.updateFCMToken(uid: uid, token: token)
    }

    func refreshProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        let profile = await fetchOrCreateProfile(for: user)
        authStateSubject.send(.authenticated(profile))
    }

    // MARK: - Apple Sign-In Nonce

    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess { continue }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
