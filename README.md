# Mnemo

Local-first, consent-based personal memory system for iOS.

## What is Mnemo?

Mnemo captures voice/text, extracts Memory Candidates using AI, asks you to approve/edit/reject them, stores approved memories, and mirrors them to Markdown/Obsidian-compatible files.

**Core invariant:** No memory is ever stored without explicit user approval.

## MVP Scope

- Text capture with rule-based memory extraction
- Ollama LLM adapter (qwen3.5:9b)
- Approval queue: approve / edit / reject / mark temporary
- Approved memory storage (file-backed JSON)
- Markdown vault export (Obsidian-compatible)
- Project lifecycle management
- Daily reflection flow

## Architecture

```
iOS App (SwiftUI + MVVM)
  ↓
Core Services
  ├── RuleBasedMemoryExtractionEngine  (offline, no deps)
  ├── OllamaExtractionEngine           (local LLM)
  └── ApprovalService                  (ONLY path to ApprovedMemory)
  ↓
Persistence
  ├── FileBackedRepositories           (JSON, behind protocols)
  └── InMemoryRepositories             (tests/previews)
  ↓
Vault
  └── FileVaultWriter → MnemoVault/    (Markdown export)
```

## Setup

```bash
# Clone and open
git clone https://github.com/Toymen/mnemo-ios-mvp
cd mnemo-ios-mvp
brew install xcodegen
xcodegen generate
open Mnemo.xcodeproj
```

## Running the App

1. Select `iPhone 17 Pro` simulator in Xcode
2. Press ▶ or `Cmd+R`

## Running Tests

```bash
xcodebuild test \
  -project Mnemo.xcodeproj \
  -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoTests \
  CODE_SIGNING_ALLOWED=NO
```

## Ollama Setup

```bash
# Install Ollama
brew install ollama
ollama serve
ollama pull qwen3.5:9b

# The app will use Ollama automatically if running on localhost:11434
# Falls back to rule-based extraction if Ollama is unavailable
```

## Cloud LLM (Optional)

Not required. No keys needed. See `.env.example` for configuration.

## Vault Export

Approved memories are exported to `~/Documents/MnemoVault/Memories/` as Markdown files with YAML frontmatter compatible with Obsidian.

## Privacy Model

- All data stored on-device only
- No telemetry
- No network requests except optional Ollama (localhost only) or optional cloud LLM
- Memories are only created by explicit user approval
- Voice transcription runs locally via SpeechRecognition framework

## Limitations (MVP)

- No voice capture yet (text only)
- No SQLite (file-backed JSON)
- No cloud sync
- No Obsidian plugin integration
- No notification/reminder system
- Backend (Server/) is a skeleton only

## Branch

`agent/mnemo-mvp-autopilot`
