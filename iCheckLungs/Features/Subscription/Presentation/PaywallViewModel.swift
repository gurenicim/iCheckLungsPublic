//
//  PaywallViewModel.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import Foundation
import Combine

@MainActor final class PaywallViewModel: ObservableObject {
    @Published var offerings: [SubscriptionOffering] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPurchased = false

    private let subscriptionRepository: SubscriptionRepository
    private let authRepository: AuthRepositoryImpl

    init(subscriptionRepository: SubscriptionRepository, authRepository: AuthRepositoryImpl) {
        self.subscriptionRepository = subscriptionRepository
        self.authRepository = authRepository
    }

    func loadOfferings() async {
        isLoading = true
        errorMessage = nil
        do {
            offerings = try await subscriptionRepository.fetchOfferings()
        } catch {
            errorMessage = "Could not load subscription options."
        }
        isLoading = false
    }

    func purchase(_ offering: SubscriptionOffering) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await subscriptionRepository.purchase(offering)
            try await authRepository.updateSubscriptionPlan(plan: result.plan, periodEnd: result.expirationDate)
            isPurchased = true
        } catch let domainError as DomainError {
            if case .networkError(let msg) = domainError, msg == "Purchase cancelled" {
                // User tapped cancel — not an error
            } else {
                errorMessage = domainError.errorDescription
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            if let result = try await subscriptionRepository.restorePurchases() {
                try await authRepository.updateSubscriptionPlan(plan: result.plan, periodEnd: result.expirationDate)
                isPurchased = true
            } else {
                errorMessage = "No active purchases found to restore."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
        isLoading = false
    }
}
