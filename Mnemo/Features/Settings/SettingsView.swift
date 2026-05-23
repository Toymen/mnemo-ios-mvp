import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var showResetConfirm = false
    @State private var exportStatus: String?
    @State private var isExporting = false
    @State private var memoryCount = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Local-First", systemImage: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text("All data is stored on this device. Nothing is sent anywhere without your knowledge.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Memories are only created when you explicitly approve a candidate.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Vault") {
                    LabeledContent("Path") {
                        Text(container.vaultWriter.vaultPath.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: exportAll) {
                        HStack {
                            if isExporting { ProgressView().scaleEffect(0.8) }
                            Label("Export All Approved Memories", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                    if let status = exportStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("LLM Provider") {
                    LabeledContent("Active Engine") { Text("Rule-Based + Ollama") }
                    LabeledContent("Ollama Model") { Text("qwen3.5:9b") }
                    LabeledContent("Cloud LLM") {
                        Text("Not configured")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    LabeledContent("Approved Memories") { Text("\(memoryCount)") }
                    Button(role: .destructive, action: { showResetConfirm = true }) {
                        Label("Reset All Local Data", systemImage: "trash.fill")
                    }
                }

                Section("About") {
                    LabeledContent("Version") { Text("0.1.0 MVP") }
                    LabeledContent("Build") { Text("agent/mnemo-mvp-autopilot") }
                }
            }
            .navigationTitle("Settings")
        }
        .confirmationDialog("Reset all local data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all captures, candidates, and approved memories from this device. This cannot be undone.")
        }
        .task {
            let memories = try? await container.memoryRepository.fetchAllApprovedMemories()
            memoryCount = memories?.count ?? 0
        }
    }

    private func exportAll() {
        isExporting = true
        Task {
            do {
                let memories = try await container.memoryRepository.fetchAllApprovedMemories()
                var count = 0
                for memory in memories {
                    let path = try container.vaultWriter.write(memory)
                    var updated = memory
                    updated.markdownPath = path
                    try await container.memoryRepository.updateApprovedMemory(updated)
                    count += 1
                }
                exportStatus = "Exported \(count) memories to vault."
            } catch {
                exportStatus = "Export failed: \(error.localizedDescription)"
            }
            isExporting = false
        }
    }
}
