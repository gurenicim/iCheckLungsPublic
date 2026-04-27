//
//  AuthenticationView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        TabView {
            LoginView()
                .tabItem { Label("Sign In", systemImage: "person.fill") }
            RegisterView()
                .tabItem { Label("Register", systemImage: "person.badge.plus") }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
