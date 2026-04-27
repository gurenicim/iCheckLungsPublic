//
//  PaywallView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import SwiftUI

struct PaywallView: View {
    @ObservedObject var viewModel: PaywallViewModel
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    trialBadge
                    offeringsSection
                    restoreButton
                    legalNote
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Get Full Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { onDismiss?() }
                }
            }
            .task { await viewModel.loadOfferings() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.isPurchased) { _, purchased in
                if purchased { onDismiss?() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 56))
                .foregroundColor(.blue)
            Text("AI Lung Analysis")
                .font(.title.bold())
            Text("Get expert-level chest X-ray analysis powered by MedGemma AI.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    private var trialBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Free Trial Included")
                    .font(.subheadline.bold())
                Text("New users get 1 free scan — no subscription required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(14)
    }

    private var offeringsSection: some View {
        VStack(spacing: 12) {
            if viewModel.offerings.isEmpty && !viewModel.isLoading {
                Text("No plans available. Please try again later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.offerings) { offering in
                    OfferingCard(offering: offering) {
                        Task { await viewModel.purchase(offering) }
                    }
                }
            }
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await viewModel.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundColor(.blue)
    }

    private var legalNote: some View {
        Text("Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple ID settings.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Offering Card

private struct OfferingCard: View {
    let offering: SubscriptionOffering
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offering.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(offering.scansPerPeriod) scans per \(offering.period.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(offering.priceString)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
