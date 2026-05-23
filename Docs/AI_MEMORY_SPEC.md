# AI Memory Specification

## Candidate Types

| Type | Description |
|------|-------------|
| `preference` | User preference or taste |
| `project` | Active work item |
| `goal` | Intention or target |
| `learning` | Knowledge gained |
| `statusChange` | State transition |
| `clarificationNeeded` | Ambiguous reference |
| `general` | Unclassified note |

## Extraction Flow

```
Capture.effectiveText
  → MemoryExtractionEngine.extractCandidates()
  → [MemoryCandidate] (status: .pending)
  → ApprovalQueue (user sees candidates)
  → ApprovalService.approve() → ApprovedMemory
                OR
  → ApprovalService.reject() → candidate.status = .rejected
```

## LLM JSON Schema

```json
{
  "candidates": [
    {
      "type": "preference|project|goal|learning|statusChange|clarificationNeeded|general",
      "proposedText": "string (required, non-empty)",
      "confidence": 0.85,
      "reason": "string (required, non-empty)",
      "suggestedProjectName": "string or null",
      "clarificationQuestion": "string or null"
    }
  ]
}
```

## Validation Rules

- `confidence` clamped to [0, 1]
- `proposedText` must be non-empty
- `reason` must be non-empty
- `type` must be a valid CandidateType value
- Malformed output is discarded silently (no crash)
- No auto-approval under any circumstances

## Rule-Based Patterns

Trigger phrases → CandidateType:
- "i learned" / "i've learned" / "i realized" / "i discovered" → `learning`
- "i prefer" / "i don't like" / "i no longer" → `preference`
- "i want to focus on" / "my goal is" / "i decided" → `goal`
- "i'm working on" / "i am working on" / "i started" → `project`
- "the status of" / "is now" → `statusChange`
- Ambiguous terms without pattern match → `clarificationNeeded`
- Anything else (>20 chars) → `general`
