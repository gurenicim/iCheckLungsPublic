//
//  AppDependencies.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import Combine

final class AppDependencies {
    static let shared = AppDependencies()

    let authRepository: AuthRepositoryImpl
    let authViewModel: AuthViewModel
    let scanViewModel: ScanViewModel
    let historyViewModel: HistoryViewModel
    let paywallViewModel: PaywallViewModel

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Services
        let firestoreService = FirestoreService.shared
        let storageService = StorageService.shared

        // Auth
        authRepository = AuthRepositoryImpl(firestoreService: firestoreService)

        let signInEmail    = SignInWithEmailUseCase(repository: authRepository)
        let registerEmail  = RegisterWithEmailUseCase(repository: authRepository)
        let signInApple    = SignInWithAppleUseCase(repository: authRepository)
        let signInGoogle   = SignInWithGoogleUseCase(repository: authRepository)
        let signOut        = SignOutUseCase(repository: authRepository)

        authViewModel = AuthViewModel(
            signInWithEmailUseCase: signInEmail,
            registerWithEmailUseCase: registerEmail,
            signInWithAppleUseCase: signInApple,
            signInWithGoogleUseCase: signInGoogle,
            signOutUseCase: signOut,
            authRepositoryImpl: authRepository
        )

        // Subscription
        let subscriptionRepository = SubscriptionRepositoryImpl()
        paywallViewModel = PaywallViewModel(
            subscriptionRepository: subscriptionRepository,
            authRepository: authRepository
        )

        // Scan
        let httpClient = URLSessionHTTPClient()
        let scanRepository = ScanRepositoryImpl(
            client: httpClient,
            storageService: storageService,
            firestoreService: firestoreService
        )
        let analyzeScanUseCase     = AnalyzeScanUseCase(repository: scanRepository)
        let fetchScanResultUseCase = FetchScanResultUseCase(repository: scanRepository)

        scanViewModel = ScanViewModel(
            analyzeScanUseCase: analyzeScanUseCase,
            fetchScanResultUseCase: fetchScanResultUseCase
        )

        // History
        let historyRepository = HistoryRepositoryImpl(firestoreService: firestoreService, storageService: storageService)
        let observeHistoryUseCase = ObserveHistoryUseCase(repository: historyRepository)
        historyViewModel = HistoryViewModel(observeHistoryUseCase: observeHistoryUseCase, historyRepository: historyRepository)

        // Wire Firestore listener as FCM fallback:
        // when historyViewModel sees a pending scan flip to done, drive scanViewModel directly
        let sv = scanViewModel
        historyViewModel.scanCompletedPublisher
            .sink { payload in
                Task { await sv.onScanComplete(scanId: payload.scanId, userId: payload.userId) }
            }
            .store(in: &cancellables)
    }
}
