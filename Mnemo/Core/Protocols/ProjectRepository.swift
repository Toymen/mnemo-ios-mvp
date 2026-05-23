import Foundation

protocol ProjectRepository: Sendable {
    func save(_ project: Project) async throws
    func fetch(id: UUID) async throws -> Project?
    func fetchAll() async throws -> [Project]
    func update(_ project: Project) async throws
    func delete(id: UUID) async throws
}
