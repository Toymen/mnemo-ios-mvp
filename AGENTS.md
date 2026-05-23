# AGENTS.md — Mnemo iOS

> Universal AI agent configuration. Read this before touching any file.
> Claude Code users: `CLAUDE.md` adds Claude-specific rules on top of this.

## Project

Mnemo is a local-first iOS memory assistant. Users capture text or voice notes;
an LLM extracts `MemoryCandidate`s; the user approves them; approved memories
write to an Obsidian-compatible Markdown vault.

**Platform:** iOS 17+ · SwiftUI · Swift 5.9/6.x  
**Generator:** XcodeGen (`project.yml` → `Mnemo.xcodeproj`)  
**Persistence:** File-backed JSON (InMemory for tests)  
**LLM adapters:** RuleBased (always on) → Ollama (local) → Cloud (stub)

## Core Invariant — BLOCKING DEFECT if violated

**The LLM must NEVER directly create `ApprovedMemory`.**

```
Capture → MemoryCandidate → ApprovalService.approve() → ApprovedMemory
```

Every new feature must be checked against this before opening a PR.
`ApprovalService` is the only legal gateway to `ApprovedMemory`.

## Build & Test

```bash
# Regenerate Xcode project after editing project.yml
xcodegen generate

# Build (no signing required)
xcodebuild build -project Mnemo.xcodeproj -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO

# Run unit tests
xcodebuild test -project Mnemo.xcodeproj -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoTests \
  CODE_SIGNING_ALLOWED=NO
```

CI runs both on every PR targeting `main`. PRs must be green before merge.

## Architecture

```
Mnemo/
  App/           — AppContainer (DI root), ContentView, MnemoApp
  Core/
    Models/      — Capture, MemoryCandidate, ApprovedMemory, Project, DailyReflection
    Protocols/   — Repository and engine protocols (testability boundary)
    Services/    — ApprovalService (gateway), extraction engines, vault writers
  Features/      — SwiftUI views + @Observable ViewModels per feature
  Persistence/
    FileBacked/  — Production JSON stores
    InMemory/    — Test doubles
```

- All repos and engines are accessed through protocols — never reference concrete
  types in feature code, inject via `AppContainer`.
- `ApprovalService` is the single write path to `ApprovedMemory`.
- `SpeechRecognizer` wraps `SFSpeechRecognizer` + `AVAudioEngine` with a
  silence-aware segment-restart loop (Apple's 60 s limit is invisible to callers).

## Coding Conventions

- No comments unless the WHY is non-obvious
- No auto-approval anywhere — user must always act
- Validate all LLM output: `confidence` ∈ [0,1], non-empty `proposedText` and `reason`
- `async/await` throughout — no callbacks, no Combine
- `InMemory` repos for tests; `FileBacked` repos for production
- `@Observable` + `@Bindable` — no `ObservableObject`

## Commit Format

```
type(scope): summary
```

Types: `feat` `fix` `chore` `refactor` `test` `docs` `build` `ci`  
Scopes: feature name or layer, e.g. `capture`, `speech`, `approval`, `nav`, `ci`

Breaking changes: append `!` → `feat(approval)!: rename ApprovalService`  
Or add a `BREAKING CHANGE:` footer.

## PR Expectations

- One logical change per PR, linked to an issue where possible
- All unit tests pass locally before pushing
- PR description fills `.github/pull_request_template.md`
- Approval invariant checkbox ticked
- PR is labeled with the matching commit type (`feat`, `fix`, etc.)

## Agent Context Files

Read before making changes — they describe the project state an agent left off at:

| File | Contains |
|---|---|
| `.agent/GOALS.md` | Top-level goals and completion status |
| `.agent/TASKS.md` | In-progress and queued tasks |
| `.agent/STATUS.md` | Current build state |
| `.agent/DECISIONS.md` | Architecture decisions and rationale |
| `.agent/TOKEN_STRATEGY.md` | Context economy rules |

## Hard Rules

- Never instantiate `ApprovedMemory` directly — always via `ApprovalService.approve()`
- Never commit `Mnemo.xcodeproj` changes without running `xcodegen generate` first
- Never merge a PR with failing CI
- Never add a third-party dependency without a decision record in `.agent/DECISIONS.md`
- Never push directly to `main` — branch protection enforces PRs
