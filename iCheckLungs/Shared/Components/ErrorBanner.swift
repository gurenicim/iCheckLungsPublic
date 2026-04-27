//
//  ErrorBanner.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI

struct ErrorBanner: View {
    let error: DomainError
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(error.errorDescription ?? "An error occurred.")
                .foregroundColor(.white)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
