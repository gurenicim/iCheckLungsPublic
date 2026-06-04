//
//  SubscriptionRepositoryImpl.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import Foundation
import RevenueCat

final class SubscriptionRepositoryImpl: SubscriptionRepository {
    // Maps offering id → RC Package, populated during fetchOfferings()
    private var packageCache: [String: Package] = [:]

    func fetchOfferings() async throws -> [SubscriptionOffering] {
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else { return [] }

        packageCache.removeAll()
        var result: [SubscriptionOffering] = []

        for package in current.availablePackages {
            guard let offering = map(package: package) else { continue }
            packageCache[offering.id] = package
            result.append(offering)
        }

        // Sort: weekly first
        return result.sorted { $0.period == .weekly && $1.period == .monthly }
    }

    func purchase(_ offering: SubscriptionOffering) async throws -> PurchaseResult {
        guard let package = packageCache[offering.id] else {
            throw DomainError.unknown
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            throw DomainError.networkError("Purchase cancelled")
        }
        let expiry = result.customerInfo.entitlements.active.values.first?.expirationDate
        let plan: UserPlan = offering.period == .weekly ? .weekly : .monthly
        return PurchaseResult(plan: plan, expirationDate: expiry)
    }

    func restorePurchases() async throws -> PurchaseResult? {
        let customerInfo = try await Purchases.shared.restorePurchases()
        guard !customerInfo.activeSubscriptions.isEmpty else { return nil }

        if packageCache.isEmpty {
            _ = try? await fetchOfferings()
        }

        for productId in customerInfo.activeSubscriptions {
            for (_, package) in packageCache where package.storeProduct.productIdentifier == productId {
                let plan: UserPlan = package.packageType == .weekly ? .weekly : .monthly
                let expiry = customerInfo.entitlements.active.values
                    .first(where: { $0.productIdentifier == productId })?.expirationDate
                return PurchaseResult(plan: plan, expirationDate: expiry)
            }
        }

        let expiry = customerInfo.entitlements.active.values.first?.expirationDate
        return PurchaseResult(plan: .monthly, expirationDate: expiry)
    }

    // MARK: - Private

    private func map(package: Package) -> SubscriptionOffering? {
        let product = package.storeProduct
        let period: SubscriptionPeriod

        switch package.packageType {
        case .weekly:  period = .weekly
        case .monthly: period = .monthly
        default:       return nil
        }

        let scans = period == .weekly ? 5 : 20
        let periodLabel = period.displayName

        return SubscriptionOffering(
            id: period.rawValue,
            displayName: period == .weekly ? "Weekly Plan" : "Monthly Plan",
            priceString: "\(product.localizedPriceString)/\(periodLabel)",
            scansPerPeriod: scans,
            period: period
        )
    }
}
