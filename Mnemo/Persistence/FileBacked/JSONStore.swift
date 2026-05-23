import Foundation

actor JSONStore<T: Codable & Identifiable & Sendable> where T.ID == UUID {
    private let fileURL: URL
    private var cache: [UUID: T] = [:]
    private var loaded = false

    init(filename: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("MnemoData/\(filename).json")
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func save(_ item: T) throws {
        try ensureLoaded()
        cache[item.id] = item
        try persist()
    }

    func fetch(id: UUID) throws -> T? {
        try ensureLoaded()
        return cache[id]
    }

    func fetchAll() throws -> [T] {
        try ensureLoaded()
        return Array(cache.values).sorted { "\($0.id)" < "\($1.id)" }
    }

    func update(_ item: T) throws {
        try ensureLoaded()
        cache[item.id] = item
        try persist()
    }

    func delete(id: UUID) throws {
        try ensureLoaded()
        cache.removeValue(forKey: id)
        try persist()
    }

    func preload() throws {
        try ensureLoaded()
    }

    @discardableResult
    private func ensureLoaded() throws -> Bool {
        guard !loaded else { return true }
        loaded = true
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return false }
        let data = try Data(contentsOf: fileURL)
        let items = try JSONDecoder().decode([T].self, from: data)
        cache = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return true
    }

    private func persist() throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Array(cache.values))
        try data.write(to: fileURL, options: .atomicWrite)
    }
}
