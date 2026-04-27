//
//  ProfileView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 6.04.2026.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel
    @State private var showPaywall = false

    var paywallViewModel: PaywallViewModel

    private var user: UserProfile? { authViewModel.currentUser }

    var body: some View {
        List {
            accountSection
            subscriptionSection
            manageSection
            accountActionsSection
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showPaywall) {
            PaywallView(viewModel: paywallViewModel) { showPaywall = false }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            HStack(spacing: 16) {
                avatarCircle
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.displayName ?? "User")
                        .font(.headline)
                    if let email = user?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section("Subscription") {
            planRow
            if let plan = user?.plan, plan.isActive {
                scansRemainingRow
                if let periodEnd = user?.subscriptionPeriodEnd {
                    LabeledContent("Renews") {
                        Text(periodEnd, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            if !(user?.plan.isActive ?? false) {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Subscribe for Full Access")
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Text("Change Plan")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private var planRow: some View {
        LabeledContent("Plan") {
            Text(user?.plan.displayName ?? "No active plan")
                .foregroundColor(user?.plan.isActive == true ? .green : .secondary)
                .fontWeight(user?.plan.isActive == true ? .semibold : .regular)
        }
    }

    private var scansRemainingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Scans remaining") {
                Text("\(user?.scansRemaining ?? 0) / \(user?.scansLimit ?? 0)")
                    .foregroundColor(.secondary)
            }
            let remaining = Double(user?.scansRemaining ?? 0)
            let limit = Double(user?.scansLimit ?? 1)
            ProgressView(value: remaining, total: max(limit, 1))
                .tint(remaining / max(limit, 1) < 0.25 ? .red : .blue)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Manage Section

    private var manageSection: some View {
        Section("Manage") {
            Button {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Manage Subscription", systemImage: "creditcard")
            }
            Button {
                Task { await paywallViewModel.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Account Actions Section

    private var accountActionsSection: some View {
        Section {
            Button(role: .destructive) {
                historyViewModel.stopListening()
                authViewModel.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - Avatar

    private var avatarCircle: some View {
        let initial = user?.displayName?.first.map(String.init) ?? user?.email?.first.map(String.init) ?? "?"
        return Text(initial)
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(width: 52, height: 52)
            .background(Color.blue)
            .clipShape(Circle())
    }
}
