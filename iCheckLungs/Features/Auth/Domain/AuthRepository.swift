//
//  AuthRepository.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import Foundation
import Combine
import AuthenticationServices

protocol AuthRepository {
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    var currentUser: UserProfile? { get }

    func signIn(email: String, password: String) async throws -> UserProfile
    func register(email: String, password: String) async throws -> UserProfile
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> UserProfile
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> UserProfile
    func signOut() throws
    func updateFCMToken(_ token: String) async throws
    func refreshProfile() async
}
