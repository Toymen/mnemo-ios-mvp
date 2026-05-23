import Foundation

struct LLMRequest: Sendable {
    let prompt: String
    let systemPrompt: String?
    let temperature: Double

    init(prompt: String, systemPrompt: String? = nil, temperature: Double = 0.3) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.temperature = temperature
    }
}

protocol LLMClient: Sendable {
    var isAvailable: Bool { get async }
    func complete(_ request: LLMRequest) async throws -> String
}
