//
//  ContentView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel

    var paywallViewModel: PaywallViewModel

    var body: some View {
        switch authViewModel.authState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

        case .unauthenticated:
            AuthenticationView()
                .environmentObject(authViewModel)

        case .authenticated:
            SidebarShell(paywallViewModel: paywallViewModel)
                .task {
                    if let uid = authViewModel.currentUser?.uid {
                        historyViewModel.startListening(userId: uid)
                    }
                }
        }
    }
}

// MARK: - Sidebar destinations

private enum SidebarDestination: String, CaseIterable, Identifiable {
    case scan, history, profile
    var id: String { rawValue }
}

// MARK: - Sidebar shell

private struct SidebarShell: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel
    @State private var selection: SidebarDestination? = .scan

    var paywallViewModel: PaywallViewModel

    var body: some View {
        NavigationSplitView {
            List(SidebarDestination.allCases, selection: $selection) { dest in
                switch dest {
                case .scan:
                    Label("Scan", systemImage: "lungs.fill").tag(dest)
                case .history:
                    Label("History", systemImage: "clock.fill").tag(dest)
                case .profile:
                    Label("Profile", systemImage: "person.crop.circle").tag(dest)
                }
            }
            .navigationTitle("iCheckLungs")
        } detail: {
            switch selection ?? .scan {
            case .scan:
                NavigationStack { ScanView(paywallViewModel: paywallViewModel) }
            case .history:
                NavigationStack { HistoryView() }
            case .profile:
                NavigationStack {
                    ProfileView(paywallViewModel: paywallViewModel)
                }
            }
        }
    }
}
