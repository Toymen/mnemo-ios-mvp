import SwiftUI

struct DailyReflectionView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var viewModel: DailyReflectionViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    DailyReflectionContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Daily Reflection")
        }
        .task {
            if viewModel == nil {
                viewModel = DailyReflectionViewModel(
                    captureRepository: container.captureRepository,
                    memoryRepository: container.memoryRepository,
                    extractionEngine: container.extractionEngine
                )
            }
        }
    }
}

private struct DailyReflectionContentView: View {
    @Bindable var viewModel: DailyReflectionViewModel

    var body: some View {
        Group {
            if viewModel.didSubmit {
                SubmittedView(count: viewModel.generatedCandidateCount) {
                    viewModel.didSubmit = false
                    viewModel.reflection = nil
                }
            } else if let reflection = viewModel.reflection {
                ReflectionFormView(
                    reflection: Binding(
                        get: { reflection },
                        set: { viewModel.reflection = $0 }
                    ),
                    isSubmitting: viewModel.isSubmitting
                ) {
                    Task { await viewModel.submitReflection() }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    Text("Ready to reflect?")
                        .font(.title2)
                    Button("Start Today's Reflection") {
                        Task { await viewModel.generateReflection() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isGenerating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct ReflectionFormView: View {
    @Binding var reflection: DailyReflection
    let isSubmitting: Bool
    let onSubmit: () -> Void

    var body: some View {
        List {
            ForEach(reflection.questions.indices, id: \.self) { i in
                Section(reflection.questions[i]) {
                    TextEditor(text: Binding(
                        get: { i < reflection.answers.count ? reflection.answers[i] : "" },
                        set: {
                            if i < reflection.answers.count { reflection.answers[i] = $0 }
                        }
                    ))
                    .frame(minHeight: 60)
                }
            }
            Section {
                Button(action: onSubmit) {
                    HStack {
                        if isSubmitting { ProgressView().scaleEffect(0.8) }
                        Text(isSubmitting ? "Generating candidates..." : "Submit Reflection")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
            }
        }
    }
}

private struct SubmittedView: View {
    let count: Int
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Reflection Complete!")
                .font(.title2)
            Text("\(count) memory candidate(s) generated.")
                .foregroundStyle(.secondary)
            Text("Review them in the Approval tab.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button("Start New Reflection") { onReset() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
