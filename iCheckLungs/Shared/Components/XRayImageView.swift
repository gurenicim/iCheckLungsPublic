//
//  XRayImageView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 2.04.2026.
//

import SwiftUI

struct XRayImageView: View {
    let scanId: String
    let userId: String

    @State private var imageURL: URL?
    @State private var isLoading = true
    @State private var hasFailed = false

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                    ProgressView()
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
            } else if hasFailed || imageURL == nil {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                    VStack(spacing: 8) {
                        Image(systemName: "lungs")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Image unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
            } else {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                            VStack(spacing: 8) {
                                Image(systemName: "lungs")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Image unavailable")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
            }
        }
        .task {
            do {
                imageURL = try await StorageService.shared.fetchDownloadURL(uid: userId, scanId: scanId)
            } catch {
                hasFailed = true
            }
            isLoading = false
        }
    }
}
