import SwiftUI
import MarkdownUI

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
                let vm = CaptureViewModel(
                    captureRepository: container.captureRepository,
                    memoryRepository: container.memoryRepository,
                    extractionEngine: container.extractionEngine
                )
                vm.speechRecognizer.locale = Locale(identifier: speechLanguage)
                viewModel = vm
                await vm.loadRecent()
            }
        }
        .onAppear {
            guard viewModel != nil else { return }
            Task { await viewModel?.loadRecent() }
        }
        .onChange(of: speechLanguage) {
            viewModel?.speechRecognizer.locale = Locale(identifier: speechLanguage)
        }
    }
}

private struct CaptureContentView: View {
    @Bindable var viewModel: CaptureViewModel

    private var speechError: String? {
        if case .error(let msg) = viewModel.speechRecognizer.state { return msg }
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

                    Button(action: { Task { await viewModel.submitCapture() } }) {
                        HStack {
                            if viewModel.isProcessing { ProgressView().scaleEffect(0.8) }
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
                        NavigationLink {
                            CaptureDetailView(capture: capture)
                        } label: {
                            CaptureRowView(capture: capture)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $viewModel.showCandidates) {
            CaptureResultSheet(
                rawText: viewModel.capturedRawText,
                enrichedMarkdown: viewModel.enrichedMarkdown,
                candidates: viewModel.generatedCandidates
            )
        }
    }
}

// MARK: - Capture Result Sheet

struct CaptureResultSheet: View {
    let rawText: String
    let enrichedMarkdown: String?
    let candidates: [MemoryCandidate]

    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @State private var approvedIds: Set<UUID> = []
    @State private var rejectedIds: Set<UUID> = []
    @State private var error: String?
    @State private var mermaidHeight: CGFloat = 320

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Original recording
                    sectionHeader("Original Recording", icon: "mic.fill")
                    Text(rawText)
                        .font(.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                    // Enriched view
                    if let md = enrichedMarkdown {
                        sectionHeader("Enriched View", icon: "sparkles")
                        enrichedCard(md: md)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }

                    // Candidates
                    if !candidates.isEmpty {
                        sectionHeader(
                            candidates.count == 1 ? "1 Memory Candidate" : "\(candidates.count) Memory Candidates",
                            icon: "brain.head.profile"
                        )
                        if let error {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                        ForEach(candidates) { candidate in
                            candidateCard(candidate)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Capture Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private func enrichedCard(md: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(iOS)
            MermaidView(markdown: md, contentHeight: $mermaidHeight)
                .frame(height: mermaidHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            #else
            Markdown(md)
                .padding(16)
            #endif
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func candidateCard(_ candidate: MemoryCandidate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TopicBadge(topic: candidate.topic)
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

            if approvedIds.contains(candidate.id) {
                Label("Approved", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            } else if rejectedIds.contains(candidate.id) {
                Label("Rejected", systemImage: "xmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task {
                            do {
                                _ = try await container.approvalService.approve(candidate: candidate)
                                approvedIds.insert(candidate.id)
                            } catch { self.error = error.localizedDescription }
                        }
                    } label: {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                    }
                    .tint(.green)
                    .buttonStyle(.bordered)

                    Button {
                        Task {
                            do {
                                try await container.approvalService.reject(candidate: candidate)
                                rejectedIds.insert(candidate.id)
                            } catch { self.error = error.localizedDescription }
                        }
                    } label: {
                        Label("Reject", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.medium))
                    }
                    .tint(.red)
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Topic Badge

struct TopicBadge: View {
    let topic: String

    var body: some View {
        Text(topic)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(topicColor.opacity(0.15))
            .foregroundStyle(topicColor)
            .clipShape(Capsule())
    }

    private var topicColor: Color {
        let palette: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo, .mint, .cyan, .brown]
        return palette[abs(topic.hashValue) % palette.count]
    }
}

// MARK: - Supporting Views

private struct CaptureRowView: View {
    let capture: Capture

    var body: some View {
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

private struct CaptureStatusLabel: View {
    let capture: Capture
    var body: some View {
        switch capture.processingStatus {
        case .processed:
            let count = capture.createdCandidateIds.count
            Label(count == 1 ? "1 candidate" : "\(count) candidates", systemImage: "sparkles")
                .font(.caption).foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.red)
        case .pending:
            Label("Processing…", systemImage: "clock")
                .font(.caption).foregroundStyle(.orange)
        }
    }
}

private struct VoiceRecordingView: View {
    let transcript: String
    let savedSegmentCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("Recording...")
                    .font(.caption).foregroundStyle(.secondary)
                if savedSegmentCount > 0 {
                    Spacer()
                    Label(
                        savedSegmentCount == 1 ? "1 segment saved" : "\(savedSegmentCount) segments saved",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption).foregroundStyle(.green)
                }
            }
            if transcript.isEmpty {
                Text("Listening...").foregroundStyle(.tertiary).frame(minHeight: 80, alignment: .topLeading)
            } else {
                ScrollView {
                    Text(transcript).frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: 80)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CaptureDetailView: View {
    let capture: Capture
    @EnvironmentObject private var container: AppContainer
    @State private var candidates: [MemoryCandidate] = []
    @State private var mermaidHeight: CGFloat = 300
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Raw text
                GroupBox {
                    Text(capture.rawText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Label(
                        capture.inputType == .voice ? "Voice" : "Text",
                        systemImage: capture.inputType == .voice ? "mic.fill" : "text.bubble.fill"
                    )
                }
                .padding(.horizontal)

                // Enriched markdown
                if let md = capture.enrichedMarkdown {
                    GroupBox {
                        #if os(iOS)
                        MermaidView(markdown: md, contentHeight: $mermaidHeight)
                            .frame(height: mermaidHeight)
                        #else
                        Markdown(md).padding(4)
                        #endif
                    } label: {
                        Label("Enriched View", systemImage: "sparkles")
                    }
                    .padding(.horizontal)
                }

                // Candidates
                if candidates.isEmpty && capture.processingStatus == .processed {
                    ContentUnavailableView("No Candidates", systemImage: "sparkles")
                        .padding(.horizontal)
                } else {
                    ForEach(candidates) { candidate in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TopicBadge(topic: candidate.topic)
                                    Spacer()
                                    Text("\(Int(candidate.confidence * 100))%")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Text(candidate.proposedText)
                                Text(candidate.reason)
                                    .font(.caption).foregroundStyle(.secondary)
                                statusView(candidate)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Capture Detail")
        .task { await loadCandidates() }
    }

    @ViewBuilder
    private func statusView(_ candidate: MemoryCandidate) -> some View {
        switch candidate.status {
        case .pending:
            HStack(spacing: 12) {
                Button { Task { await approve(candidate) } } label: {
                    Label("Approve", systemImage: "checkmark.circle.fill").font(.caption)
                }
                .tint(.green)
                Button(role: .destructive) { Task { await reject(candidate) } } label: {
                    Label("Reject", systemImage: "xmark.circle.fill").font(.caption)
                }
            }
        default:
            Label(candidate.status.rawValue.capitalized, systemImage: statusIcon(candidate.status))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func loadCandidates() async {
        do {
            let all = try await container.memoryRepository.fetchAllCandidates()
            candidates = all.filter { $0.sourceCaptureId == capture.id }.sorted { $0.createdAt > $1.createdAt }
        } catch { self.error = error.localizedDescription }
    }

    private func approve(_ candidate: MemoryCandidate) async {
        do {
            _ = try await container.approvalService.approve(candidate: candidate)
            await loadCandidates()
        } catch { self.error = error.localizedDescription }
    }

    private func reject(_ candidate: MemoryCandidate) async {
        do {
            try await container.approvalService.reject(candidate: candidate)
            await loadCandidates()
        } catch { self.error = error.localizedDescription }
    }

    private func statusIcon(_ status: CandidateStatus) -> String {
        switch status {
        case .approved, .edited: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .temporary: return "clock.fill"
        case .pending: return "circle"
        }
    }
}
