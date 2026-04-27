//
//  AuthViewModel.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI
import Combine
import AuthenticationServices
import GoogleSignIn
import FirebaseCore

@MainActor final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var error: DomainError?
    @Published var isLoading = false

    private let signInWithEmailUseCase: SignInWithEmailUseCase
    private let registerWithEmailUseCase: RegisterWithEmailUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let signInWithGoogleUseCase: SignInWithGoogleUseCase
    private let signOutUseCase: SignOutUseCase
    private let authRepositoryImpl: AuthRepositoryImpl

    var currentUser: UserProfile? {
        if case .authenticated(let profile) = authState { return profile }
        return nil
    }

    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger(category: .auth)

    init(
        signInWithEmailUseCase: SignInWithEmailUseCase,
        registerWithEmailUseCase: RegisterWithEmailUseCase,
        signInWithAppleUseCase: SignInWithAppleUseCase,
        signInWithGoogleUseCase: SignInWithGoogleUseCase,
        signOutUseCase: SignOutUseCase,
        authRepositoryImpl: AuthRepositoryImpl
    ) {
        self.signInWithEmailUseCase = signInWithEmailUseCase
        self.registerWithEmailUseCase = registerWithEmailUseCase
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.signInWithGoogleUseCase = signInWithGoogleUseCase
        self.signOutUseCase = signOutUseCase
        self.authRepositoryImpl = authRepositoryImpl

        authRepositoryImpl.authStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$authState)
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            _ = try await signInWithEmailUseCase.execute(email: email, password: password)
            logger.info("Sign in successful")
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .authError(error.localizedDescription)
        }
        isLoading = false
    }

    func register(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            _ = try await registerWithEmailUseCase.execute(email: email, password: password)
            logger.info("Registration successful")
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .authError(error.localizedDescription)
        }
        isLoading = false
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        error = nil
        do {
            _ = try await signInWithAppleUseCase.execute(credential: credential)
            logger.info("Apple sign in successful")
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .authError(error.localizedDescription)
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            error = .authError("Missing Firebase client ID.")
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            error = .authError("No root view controller found.")
            return
        }

        isLoading = true
        error = nil
        do {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw DomainError.authError("Missing Google ID token.")
            }
            let accessToken = result.user.accessToken.tokenString
            _ = try await signInWithGoogleUseCase.execute(idToken: idToken, accessToken: accessToken)
            logger.info("Google sign in successful")
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .authError(error.localizedDescription)
        }
        isLoading = false
    }

    func signOut() {
        do {
            try signOutUseCase.execute()
            logger.info("Sign out successful")
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .authError(error.localizedDescription)
        }
    }

    // Exposed for LoginView's Sign in with Apple button
    func appleSignInNonce() -> String {
        authRepositoryImpl.generateNonce()
    }
}
