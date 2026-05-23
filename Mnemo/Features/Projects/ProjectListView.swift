import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var projects: [Project] = []
    @State private var showCreate = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder",
                        description: Text("Create a project to track your work.")
                    )
                } else {
                    List {
                        ForEach(projects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project, repository: container.projectRepository) {
                                    Task { await load() }
                                }
                            } label: {
                                ProjectRowView(project: project)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateProjectView(repository: container.projectRepository) {
                    Task { await load() }
                }
            }
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            projects = try await container.projectRepository.fetchAll()
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                ProjectStatusBadge(status: project.status)
            }
            if !project.summary.isEmpty {
                Text(project.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ProjectStatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .active: return .green
        case .passive: return .blue
        case .dormant: return .orange
        case .archived: return .gray
        }
    }
}

struct ProjectDetailView: View {
    @State var project: Project
    let repository: any ProjectRepository
    let onUpdate: () -> Void
    @State private var isSaving = false
    @State private var newLearning = ""

    var body: some View {
        Form {
            Section("Project") {
                TextField("Name", text: $project.name)
                TextField("Summary", text: $project.summary, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            Section("Status") {
                ProjectStatusPicker(status: $project.status)
            }
            Section("Learnings") {
                ForEach(project.learnings, id: \.self) { learning in
                    Text(learning)
                }
                HStack {
                    TextField("Add learning...", text: $newLearning)
                    Button("Add") {
                        guard !newLearning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        project.learnings.append(newLearning.trimmingCharacters(in: .whitespacesAndNewlines))
                        newLearning = ""
                    }
                    .disabled(newLearning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        isSaving = true
                        project.updatedAt = Date()
                        try? await repository.update(project)
                        isSaving = false
                        onUpdate()
                    }
                }
                .disabled(isSaving)
            }
        }
    }
}

struct ProjectStatusPicker: View {
    @Binding var status: ProjectStatus

    var body: some View {
        Picker("Status", selection: $status) {
            ForEach(ProjectStatus.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.menu)
    }
}

struct CreateProjectView: View {
    let repository: any ProjectRepository
    let onCreated: () -> Void
    @State private var name = ""
    @State private var summary = ""
    @State private var status: ProjectStatus = .active
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Project name", text: $name)
                }
                Section("Summary") {
                    TextField("Optional summary", text: $summary, axis: .vertical)
                }
                Section("Status") {
                    ProjectStatusPicker(status: $status)
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let project = Project(name: name, status: status, summary: summary)
                        Task {
                            try? await repository.save(project)
                            onCreated()
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
