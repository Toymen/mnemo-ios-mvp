import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var container: AppContainer
    @AppStorage("speechLanguage") private var speechLanguage: String = "en-US"
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
        .onChange(of: speechLanguage) {
            viewModel?.speechRecognizer.locale = Locale(identifier: speechLanguage)
        }
    }
}

private struct CaptureContentView: View {
    @Bindable var viewModel: CaptureViewModel

    private var speechError: String? {
        if case .error(let msg) = viewModel.speechRecognizer.state {
            return msg
        }
        return nil
    }

    var body: some View {
        List {
            Section("New Capture") {
                if viewModel.speechRecognizer.isRecording {
                    VoiceRecordingView(
                        transcript: viewModel.speechRecognizer.transcript,
                        savedSegmentCount: viewModel.savedSegmentCount
                    )
                } else {
                    TextEditor(text: $viewModel.rawText)
                        .frame(minHeight: 100)
                }

                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleRecording() }) {
                        Label(
                            viewModel.speechRecognizer.isRecording ? "Stop" : "Voice",
                            systemImage: viewModel.speechRecognizer.isRecording ? "stop.circle.fill" : "mic.fill"
                        )
                        .foregroundStyle(viewModel.speechRecognizer.isRecording ? .red : .blue)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isProcessing)

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
                    .disabled(!viewModel.canSubmit)
                }
            }

            if let error = viewModel.error ?? speechError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if !viewModel.recentCaptures.isEmpty {
                Section("Recent Captures") {
                    ForEach(viewModel.recentCaptures) { capture in
                        HStack(spacing: 12) {
                            Image(systemName: capture.inputType == .voice ? "mic.fill" : "text.bubble.fill")
                                .foregroundStyle(capture.inputType == .voice ? .blue : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(capture.rawText)
                                    .lineLimit(2)
                                    .font(.body)
                                HStack {
                                    CaptureStatusLabel(capture: capture)
                                    Spacer()
                                    Text(capture.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
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

private struct CaptureStatusLabel: View {
    let capture: Capture

    var body: some View {
        switch capture.processingStatus {
        case .processed:
            let count = capture.createdCandidateIds.count
            Label(
                count == 1 ? "1 candidate" : "\(count) candidates",
                systemImage: "sparkles"
            )
            .font(.caption)
            .foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .pending:
            Label("Processing…", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.orange)
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

private struct VoiceRecordingView: View {
    let transcript: String
    let savedSegmentCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if savedSegmentCount > 0 {
                    Spacer()
                    Label(
                        savedSegmentCount == 1 ? "1 segment saved" : "\(savedSegmentCount) segments saved",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.green)
                }
            }

            if transcript.isEmpty {
                Text("Listening...")
                    .foregroundStyle(.tertiary)
                    .frame(minHeight: 80, alignment: .topLeading)
            } else {
                ScrollView {
                    Text(transcript)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: 80)
            }
        }
        .padding(.vertical, 4)
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
