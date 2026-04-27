//
//  HistoryView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 28.03.2026.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: HistoryViewModel
    @State private var selectedItem: ScanHistoryItem?

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("History")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(item: $selectedItem) { item in
            if let result = item.toScanResult() {
                ResultsView(result: result) { selectedItem = nil }
            }
        }
    }

    private var list: some View {
        List(viewModel.items) { item in
            Button {
                if item.status == .done { selectedItem = item }
            } label: {
                HistoryRowView(item: item)
            }
            .buttonStyle(.plain)
            .disabled(item.toScanResult() == nil)
            .listRowBackground(Color(.secondarySystemGroupedBackground))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No scans yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Your analysis history will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct HistoryRowView: View {
    let item: ScanHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 4) {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.bold())
                if let findings = item.findings {
                    Text(findings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(item.status == .failed ? "Failed" : "Processing…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if item.status == .done {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let confidence = item.confidence {
                confidenceBadge(confidence)
            }
        }
        .padding(.vertical, 4)
        .opacity(item.status == .done ? 1.0 : 0.6)
    }

    private var statusIcon: some View {
        Group {
            switch item.status {
            case .done:
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill").foregroundColor(.red)
            default:
                ProgressView().scaleEffect(0.7)
            }
        }
        .font(.title3)
        .frame(width: 28)
    }

    private func confidenceBadge(_ confidence: Confidence) -> some View {
        Text(confidence.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor(confidence).opacity(0.15))
            .foregroundColor(confidenceColor(confidence))
            .cornerRadius(8)
    }

    private func confidenceColor(_ confidence: Confidence) -> Color {
        switch confidence {
        case .high:    return .green
        case .medium:  return .orange
        case .low:     return .red
        case .unknown: return .gray
        }
    }
}
