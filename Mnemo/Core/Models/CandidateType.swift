import Foundation

enum CandidateType: String, Codable, CaseIterable, Sendable {
    case preference
    case project
    case goal
    case learning
    case statusChange
    case clarificationNeeded
    case general
}
