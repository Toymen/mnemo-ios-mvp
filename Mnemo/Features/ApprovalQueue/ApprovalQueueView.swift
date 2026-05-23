import SwiftUI

struct ApprovalQueueView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var viewModel: ApprovalQueueViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ApprovalQueueContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Review")
        }
        .task {
            if viewModel == nil {
                viewModel = ApprovalQueueViewModel(
                    memoryRepository: container.memoryRepository,
                    approvalService: container.approvalService
                )
                await viewModel?.load()
            }
        }
        .onAppear {
            guard viewModel != nil else { return }
            Task { await viewModel?.load() }
        }
    }
}

private struct ApprovalQueueContentView: View {
    @Bindable var viewModel: ApprovalQueueViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading candidates...")
            } else if viewModel.pendingCandidates.isEmpty {
                ContentUnavailableView(
                    "No Pending Candidates",
                    systemImage: "checkmark.circle",
                    description: Text("Capture something to generate memory candidates.")
                )
            } else {
                List {
                    if let error = viewModel.error {
                        Section {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                    ForEach(viewModel.pendingCandidates) { candidate in
                        NavigationLink {
                            CandidateDetailView(candidate: candidate, viewModel: viewModel)
                        } label: {
                            CandidateRowView(candidate: candidate)
                        }
                    }
                }
            }
        }
        .refreshable { await viewModel.load() }
    }
}

private struct CandidateRowView: View {
    let candidate: MemoryCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TypeBadge(type: candidate.type)
                Spacer()
                Text("\(Int(candidate.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(candidate.proposedText)
                .lineLimit(2)
            Text(candidate.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
