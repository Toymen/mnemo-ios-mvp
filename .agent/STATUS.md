# Build Status

## Phase: 1-4 Complete (Foundation + Domain + Capture + Approval)
**Date:** 2026-05-23

## Completed
- G1: Repo foundation — iOS app builds, GitHub repo created
- G2: Domain models + approval invariant enforced via ApprovalService
- G3: File-backed JSON persistence + InMemory repos
- G4: Capture flow (text input → extraction → candidates)
- G5: RuleBasedMemoryExtractionEngine + OllamaExtractionEngine + MockLLMExtractionEngine
- G6: Approval queue (list/approve/edit/reject/temporary)
- G7: ApprovedMemory stored via ApprovalService
- G8: MarkdownExporter + FileVaultWriter
- G9: Project lifecycle (active/passive/dormant/archived)
- G10: Daily reflection (questions → answers → capture → candidates)
- G12: 41 unit tests — all pass
- G13: README, CLAUDE.md, Docs/, CI workflow

## Test Results
41/41 unit tests passed on iPhone 17 Pro simulator

## Latest Commit
- Pending first commit

## Push Status
- GitHub repo: https://github.com/Toymen/mnemo-ios-mvp
- Remote: origin set

## What Remains
- G11: Ollama integration test (requires `ollama serve`)
- Voice capture (AudioRecorderService + SpeechTranscriptionService)
- SQLite persistence layer
- File-backed JSON VaultWriter test
- UI tests beyond tab existence checks
- Server/ full implementation

## Run Locally
```bash
brew install xcodegen
xcodegen generate
xcodebuild test -project Mnemo.xcodeproj -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoTests CODE_SIGNING_ALLOWED=NO
```
