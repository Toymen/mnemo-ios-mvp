import Foundation

protocol CaptureRepository: Sendable {
    func save(_ capture: Capture) async throws
    func fetch(id: UUID) async throws -> Capture?
    func fetchAll() async throws -> [Capture]
    func update(_ capture: Capture) async throws
    func delete(id: UUID) async throws
}
