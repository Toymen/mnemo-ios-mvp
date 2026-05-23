import Foundation

enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active
    case passive
    case dormant
    case archived

    var label: String { rawValue.capitalized }

    var allowedTransitions: Set<ProjectStatus> {
        switch self {
        case .active:   return [.passive, .dormant, .archived]
        case .passive:  return [.active, .dormant, .archived]
        case .dormant:  return [.active, .passive, .archived]
        case .archived: return [.active]
        }
    }

    func canTransition(to next: ProjectStatus) -> Bool {
        allowedTransitions.contains(next)
    }
}

struct Project: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var status: ProjectStatus
    var summary: String
    var learnings: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        status: ProjectStatus = .active,
        summary: String = "",
        learnings: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.summary = summary
        self.learnings = learnings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
