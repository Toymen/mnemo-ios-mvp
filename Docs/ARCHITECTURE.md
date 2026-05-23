# Architecture

## iOS App

MVVM with `@Observable` view models. SwiftUI throughout.

### Layers

```
Views (SwiftUI)
  ↓ @EnvironmentObject AppContainer
ViewModels (@Observable, @MainActor)
  ↓ protocol calls
Services (pure Swift, Sendable)
  ↓ protocol calls
Repositories (actor-based)
  ↓
Storage (JSON files / SQLite future)
```

### Approval Invariant

`ApprovalService` is the **only** code path that instantiates `ApprovedMemory`.
All other code works with `MemoryCandidate` (pending/approved/rejected/edited/temporary).

### Persistence

- `FileBackedCaptureRepository` / `FileBackedMemoryRepository` / `FileBackedProjectRepository`
- All backed by `JSONStore<T>` (actor-isolated, atomic writes)
- `InMemory*` variants for tests
- SQLite: planned, skeleton at `Persistence/SQLite/`

### LLM Adapters

1. `RuleBasedMemoryExtractionEngine` — pattern matching, no deps
2. `OllamaExtractionEngine` — local LLM, falls back to rule-based
3. `MockLLMExtractionEngine` — for tests and previews

### Markdown Vault

`MarkdownExporter` → `FileVaultWriter`
Output: `~/Documents/MnemoVault/Memories/<date>-<id>-<slug>.md`
Format: YAML frontmatter + memory text + reason + source

## Backend (Skeleton)

`Server/` contains a FastAPI skeleton for a local Python backend.
Not required for the iOS app. The iOS app uses Swift services directly.
