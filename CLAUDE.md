# CLAUDE.md — Mnemo Agent Rules

## Core Invariant (NON-NEGOTIABLE)

**The LLM must NEVER directly create ApprovedMemory.**

All memory flows: `Capture → MemoryCandidate → ApprovalService.approve() → ApprovedMemory`

Any code path that bypasses this is a blocking defect.

## Build Commands

```bash
# Generate project
xcodegen generate

# Build
xcodebuild build -project Mnemo.xcodeproj -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO

# Test
xcodebuild test -project Mnemo.xcodeproj -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoTests \
  CODE_SIGNING_ALLOWED=NO
```

## Architecture

- SwiftUI + @Observable MVVM
- Protocols for all repositories and engines
- FileBacked JSON persistence (InMemory for tests)
- ApprovalService is the single gateway to ApprovedMemory
- MarkdownExporter + FileVaultWriter for vault output

## Coding Rules

- No comments unless WHY is non-obvious
- No auto-approval anywhere
- Validate all LLM output (confidence 0–1, non-empty proposedText, non-empty reason)
- Use async/await throughout
- InMemory repos for tests; FileBackedRepos for production

## Token Rules

- See .agent/TOKEN_STRATEGY.md
- Read only relevant files; never re-read full files unnecessarily
- Commits are memory; keep them atomic

## Commit Format

```
type(scope): summary
```

## Agent Files

- `.agent/GOALS.md` — top-level goals
- `.agent/TASKS.md` — task tracking
- `.agent/STATUS.md` — current build state
- `.agent/DECISIONS.md` — architecture decisions
