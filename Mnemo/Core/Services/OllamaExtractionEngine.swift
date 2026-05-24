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

    func extract(from capture: Capture, context: MemoryContext) async throws -> ExtractionResult {
        guard await isAvailable else {
            return try await fallback.extract(from: capture, context: context)
        }
        do {
            return try await extractViaOllama(capture: capture)
        } catch {
            return try await fallback.extract(from: capture, context: context)
        }
    }

    private func extractViaOllama(capture: Capture) async throws -> ExtractionResult {
        let systemPrompt = """
        You are a memory extraction assistant. Extract structured memory candidates from the user's capture.
        Return ONLY valid JSON matching this schema:
        {
          "candidates": [
            {
              "topic": "string",
              "proposedText": "string",
              "confidence": 0.0,
              "reason": "string"
            }
          ]
        }
        Rules:
        - topic: free-form label such as 'coding', 'health', 'career', 'relationships', 'finance', 'learning'
        - confidence must be between 0 and 1
        - reason is required and non-empty
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

        let candidates = try parseResponse(responseData, captureId: capture.id)
        return ExtractionResult(candidates: candidates, enrichedMarkdown: nil)
    }

    private func parseResponse(_ data: Data, captureId: UUID) throws -> [MemoryCandidate] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawCandidates = json["candidates"] as? [[String: Any]] else {
            throw ExtractionError.malformedResponse
        }

        return rawCandidates.compactMap { raw -> MemoryCandidate? in
            guard let topic = raw["topic"] as? String,
                  let proposedText = raw["proposedText"] as? String,
                  !proposedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let confidence = raw["confidence"] as? Double,
                  let reason = raw["reason"] as? String,
                  !reason.isEmpty else {
                return nil
            }
            return MemoryCandidate(
                sourceCaptureId: captureId,
                topic: topic,
                proposedText: proposedText,
                confidence: max(0, min(1, confidence)),
                reason: reason
            )
        }
    }
}

enum ExtractionError: Error {
    case malformedResponse
    case unavailable
}
