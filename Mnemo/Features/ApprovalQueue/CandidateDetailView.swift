import SwiftUI

struct CandidateDetailView: View {
    let candidate: MemoryCandidate
    let viewModel: ApprovalQueueViewModel
    @State private var editedText: String = ""
    @State private var isEditing: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Topic") {
                HStack {
                    TopicBadge(topic: candidate.topic)
                    Spacer()
                    Text("\(Int(candidate.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Proposed Memory") {
                if isEditing {
                    TextEditor(text: $editedText)
                        .frame(minHeight: 80)
                } else {
                    Text(editedText)
                        .onTapGesture { isEditing = true }
                }
                Button(isEditing ? "Done Editing" : "Edit") {
                    isEditing.toggle()
                }
                .font(.caption)
            }

            Section("Reason") {
                Text(candidate.reason)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let question = candidate.clarificationQuestion {
                Section("Clarification Needed") {
                    Label(question, systemImage: "questionmark.circle")
                        .foregroundStyle(.orange)
                }
            }

            Section("Actions") {
                Button(action: {
                    let text = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalText = text != candidate.proposedText ? text : nil
                    Task {
                        await viewModel.approve(candidate: candidate, editedText: finalText)
                        dismiss()
                    }
                }) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button(action: {
                    Task {
                        await viewModel.markTemporary(candidate: candidate)
                        dismiss()
                    }
                }) {
                    Label("Mark Temporary", systemImage: "clock.fill")
                        .foregroundStyle(.blue)
                }

                Button(role: .destructive, action: {
                    Task {
                        await viewModel.reject(candidate: candidate)
                        dismiss()
                    }
                }) {
                    Label("Reject", systemImage: "xmark.circle.fill")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Review Candidate")
        .onAppear { editedText = candidate.proposedText }
    }
}
