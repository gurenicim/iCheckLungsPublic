//
//  ScanView.swift
//  iCheckLungs
//
//  Created by Guren Icim on 24.03.2026.
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var viewModel: ScanViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var showSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showResults = false
    @State private var showPaywall = false

    var paywallViewModel: PaywallViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                header
                imagePreviewArea

                if viewModel.selectedImage != nil {
                    analyzeButton
                }

                pendingStateView

                Spacer()
            }
            .padding()

            if let error = viewModel.error {
                ErrorBanner(error: error) { viewModel.clearResult() }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") { showCamera = true }
            }
            Button("Photo Library") { showPhotoLibrary = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $viewModel.selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showPhotoLibrary) {
            CameraView(image: $viewModel.selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showResults) {
            if let result = viewModel.result {
                ResultsView(result: result) {
                    showResults = false
                    viewModel.clearResult()
                }
            }
        }
        .onChange(of: viewModel.result) { _, result in
            if result != nil { showResults = true }
        }
        .onChange(of: viewModel.error) { _, error in
            if error == .quotaExceeded {
                viewModel.clearResult()
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(viewModel: paywallViewModel) { showPaywall = false }
        }
        .task {
            await viewModel.resumePendingScanIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("iCheckLungs")
                .font(.largeTitle.bold())
            Text("Upload a radiology scan for AI analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var imagePreviewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                )

            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            viewModel.selectedImage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .padding(8)
                        }
                    }
            } else {
                Button(action: { showSourcePicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Tap to add scan")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("Camera or Photo Library")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var analyzeButton: some View {
        switch viewModel.scanPhase {
        case .uploading, .submitting, .fetching:
            Button(action: {}) {
                HStack {
                    ProgressView().tint(.white).padding(.trailing, 4)
                    Text(phaseLabel)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(true)

        default:
            Button(action: {
                if let profile = authViewModel.currentUser {
                    Task { await viewModel.submitScan(userProfile: profile) }
                }
            }) {
                Text("Analyze Scan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
    }

    @ViewBuilder
    private var pendingStateView: some View {
        if case .pending = viewModel.scanPhase {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Analyzing your X-ray…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("You'll be notified when results are ready.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private var phaseLabel: String {
        switch viewModel.scanPhase {
        case .uploading:  return "Uploading…"
        case .submitting: return "Submitting…"
        case .fetching:   return "Retrieving results…"
        default:          return "Analyzing…"
        }
    }
}
