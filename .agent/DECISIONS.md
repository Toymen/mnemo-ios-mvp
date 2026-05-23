# Architecture Decisions

## MVP Path
iOS-first, local-first. Backend is a secondary nice-to-have.

## D1: iOS Project Generation
Tool: xcodegen 2.45.4
Reason: cleanest way to generate .xcodeproj from project.yml spec without GUI.

## D2: LLM Adapter Priority
1. RuleBasedMemoryExtractionEngine (always available, no deps)
2. OllamaExtractionEngine (qwen3.5:9b — installed, requires `ollama serve`)
3. CloudLLMExtractionEngine (stub — no keys available)
No API keys found; cloud adapter is interface-only for MVP.

## D3: Persistence
Primary: file-backed JSON behind repository protocols for MVP speed.
Follow-up: SQLite (skeleton in place, migration task documented).
Reason: avoids SQLite Swift dependency setup blocking Phase 1 build.

## D4: Backend
Implement Server/ skeleton with FastAPI endpoints.
Not required for iOS app to function.
iOS app uses local Swift services directly.
Backend is a future enhancement path.

## D5: Vault Path
Default: ./MnemoVault (relative to app Documents directory on iOS, repo root for tests).

## D6: Swift Concurrency
Use async/await throughout. Minimum deployment: iOS 17 (Swift 5.9+, async/await stable).
Xcode 26 / Swift 6.3 — use strict concurrency where practical.

## D7: Test Runner
xcodebuild test -destination "platform=iOS Simulator,name=iPhone 17 Pro"
Scheme: Mnemo

## D8: Ollama Model
Default: qwen3.5:9b (largest available, good instruction following)
Fallback: llama3.1:8b
