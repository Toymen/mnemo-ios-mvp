import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var viewModel: CaptureViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    CaptureContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Capture")
        }
        .task {
            if viewModel == nil {
                viewModel = CaptureViewModel(
                    captureRepository: container.captureRepository,
                    memoryRepository: container.memoryRepository,
                    extractionEngine: container.extractionEngine
                )
                await viewModel?.loadRecent()
            }
        }
    }
}

private struct CaptureContentView: View {
    @Bindable var viewModel: CaptureViewModel

    var body: some View {
        List {
            Section("New Capture") {
                TextEditor(text: $viewModel.rawText)
                    .frame(minHeight: 100)

                Button(action: {
                    Task { await viewModel.submitCapture() }
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView().scaleEffect(0.8)
                        }
                        Text(viewModel.isProcessing ? "Processing..." : "Save & Extract")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isProcessing)
            }

            if let error = viewModel.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if !viewModel.recentCaptures.isEmpty {
                Section("Recent Captures") {
                    ForEach(viewModel.recentCaptures) { capture in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(capture.rawText)
                                .lineLimit(2)
                                .font(.body)
                            HStack {
                                Text(capture.inputType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                StatusBadge(status: capture.processingStatus.rawValue)
                                Text(capture.createdAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $viewModel.showCandidates) {
            CandidatesPreviewSheet(candidates: viewModel.generatedCandidates)
        }
    }
}

private struct StatusBadge: View {
    let status: String
    var body: some View {
        Text(status)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    private var color: Color {
        switch status {
        case "processed": return .green
        case "failed": return .red
        default: return .orange
        }
    }
}

private struct CandidatesPreviewSheet: View {
    let candidates: [MemoryCandidate]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(candidates) { candidate in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TypeBadge(type: candidate.type)
                        Spacer()
                        Text("\(Int(candidate.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(candidate.proposedText)
                        .font(.body)
                    Text(candidate.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("\(candidates.count) Candidate(s) Created")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TypeBadge: View {
    let type: CandidateType
    var body: some View {
        Text(type.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    private var color: Color {
        switch type {
        case .learning: return .blue
        case .preference: return .purple
        case .goal: return .orange
        case .project: return .green
        case .statusChange: return .yellow
        case .clarificationNeeded: return .red
        case .general: return .gray
        }
    }
}
