import Foundation

struct OllamaExtractionEngine: MemoryExtractionEngine {
    let engineName = "Ollama"
    let host: String
    let model: String
    private let fallback = RuleBasedMemoryExtractionEngine()

    init(host: String = "http://localhost:11434", model: String = "qwen3.5:9b") {
        self.host = host
        self.model = model
    }

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(host)/api/tags") else { return false }
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        }
    }

    func extractCandidates(from capture: Capture, context: MemoryContext) async throws -> [MemoryCandidate] {
        guard await isAvailable else {
            return try await fallback.extractCandidates(from: capture, context: context)
        }
        do {
            return try await extractViaOllama(capture: capture, context: context)
        } catch {
            return try await fallback.extractCandidates(from: capture, context: context)
        }
    }

    private func extractViaOllama(capture: Capture, context: MemoryContext) async throws -> [MemoryCandidate] {
        let systemPrompt = """
        You are a memory extraction assistant. Given a user's capture text, extract structured memory candidates.
        Return ONLY valid JSON matching this schema:
        {
          "candidates": [
            {
              "type": "preference|project|goal|learning|statusChange|clarificationNeeded|general",
              "proposedText": "string",
              "confidence": 0.0,
              "reason": "string",
              "suggestedProjectName": "string or null",
              "clarificationQuestion": "string or null"
            }
          ]
        }
        Rules:
        - confidence must be between 0 and 1
        - reason is required
        - proposedText is required and non-empty
        - Do not invent facts; extract only what is stated
        """

        let userPrompt = "Extract memory candidates from this capture:\n\"\"\"\n\(capture.effectiveText)\n\"\"\""

        guard let url = URL(string: "\(host)/api/generate") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "model": model,
            "prompt": userPrompt,
            "system": systemPrompt,
            "stream": false,
            "format": "json"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String,
              let responseData = responseText.data(using: .utf8) else {
            throw ExtractionError.malformedResponse
        }

        return try parseOllamaResponse(responseData, captureId: capture.id)
    }

    private func parseOllamaResponse(_ data: Data, captureId: UUID) throws -> [MemoryCandidate] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawCandidates = json["candidates"] as? [[String: Any]] else {
            throw ExtractionError.malformedResponse
        }

        return rawCandidates.compactMap { raw -> MemoryCandidate? in
            guard let typeStr = raw["type"] as? String,
                  let type_ = CandidateType(rawValue: typeStr),
                  let proposedText = raw["proposedText"] as? String,
                  !proposedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let confidence = raw["confidence"] as? Double,
                  let reason = raw["reason"] as? String,
                  !reason.isEmpty else {
                return nil
            }
            return MemoryCandidate(
                sourceCaptureId: captureId,
                type: type_,
                proposedText: proposedText,
                confidence: max(0, min(1, confidence)),
                reason: reason,
                clarificationQuestion: raw["clarificationQuestion"] as? String
            )
        }
    }
}

enum ExtractionError: Error {
    case malformedResponse
    case unavailable
}
