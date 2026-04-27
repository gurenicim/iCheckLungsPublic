//
//  ResultsView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI

struct ResultsView: View {
    let result: ScanResult
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    confidenceBadge

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Findings", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(result.findings)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Analysis Time", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
            }
            .safeAreaInset(edge: .top, content: {
                HStack {
                    XRayImageView(scanId: result.scanId, userId: result.userId)
                }
                .padding()
            })
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss?() }
                }
            }
        }
    }

    private var confidenceBadge: some View {
        HStack {
            Image(systemName: confidenceIcon)
            Text("Confidence: \(result.confidence.rawValue.capitalized)")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(confidenceColor.opacity(0.15))
        .foregroundColor(confidenceColor)
        .cornerRadius(20)
    }

    private var confidenceColor: Color {
        switch result.confidence {
        case .high:    return .green
        case .medium:  return .orange
        case .low:     return .red
        case .unknown: return .gray
        }
    }

    private var confidenceIcon: String {
        switch result.confidence {
        case .high:    return "checkmark.seal.fill"
        case .medium:  return "exclamationmark.triangle.fill"
        case .low:     return "xmark.seal.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}
