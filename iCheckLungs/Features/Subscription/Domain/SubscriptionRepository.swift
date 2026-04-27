//
//  SubscriptionRepository.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import Foundation

protocol SubscriptionRepository: AnyObject {
    func fetchOfferings() async throws -> [SubscriptionOffering]
    func purchase(_ offering: SubscriptionOffering) async throws
    func restorePurchases() async throws
}
