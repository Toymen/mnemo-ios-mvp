import SwiftUI
import MarkdownUI

struct MemoryListView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var memories: [ApprovedMemory] = []
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var error: String?

    var filtered: [ApprovedMemory] {
        guard !searchText.isEmpty else { return memories }
        return memories.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            $0.topic.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading memories...")
                } else if memories.isEmpty {
                    VStack(spacing: 16) {
                        MnemoLogo(size: .medium)
                        Text("No Memories Yet")
                            .font(.title3.weight(.semibold))
                        Text("Approve a memory candidate to see it here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { memory in
                        NavigationLink {
                            MemoryDetailView(memory: memory)
                        } label: {
                            MemoryRowView(memory: memory)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search memories")
                }
            }
            .navigationTitle("Memories")
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let all = try await container.memoryRepository.fetchAllApprovedMemories()
            memories = all.sorted { $0.createdAt > $1.createdAt }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct MemoryRowView: View {
    let memory: ApprovedMemory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TopicBadge(topic: memory.topic)
                Spacer()
                Text(memory.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(memory.text)
                .lineLimit(2)
            if let path = memory.markdownPath {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MemoryDetailView: View {
    let memory: ApprovedMemory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Memory") {
                    Markdown(memory.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Topic") { TopicBadge(topic: memory.topic) }
                        LabeledContent("Confidence") { Text("\(Int(memory.confidence * 100))%") }
                        LabeledContent("Created") { Text(memory.createdAt, style: .date) }
                    }
                } label: {
                    Text("Details")
                }

                GroupBox("Reason") {
                    Text(memory.reason)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let path = memory.markdownPath {
                    GroupBox("Vault") {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GroupBox("Source") {
                    VStack(alignment: .leading, spacing: 4) {
                        LabeledContent("Capture ID") {
                            Text(memory.sourceCaptureId.uuidString.prefix(8) + "...")
                                .font(.caption)
                        }
                        LabeledContent("Candidate ID") {
                            Text(memory.sourceCandidateId.uuidString.prefix(8) + "...")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Memory")
    }
}
