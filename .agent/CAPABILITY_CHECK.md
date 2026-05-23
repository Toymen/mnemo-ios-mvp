# Capability Check — 2026-05-23

## Repository
- Directory: /Users/A76286672/Mnemo
- Git: initialized, branch agent/mnemo-mvp-autopilot
- Remote: none yet — creating via gh
- GitHub CLI: gh 2.89.0, authenticated as Toymen (repo + workflow scopes)
- GitHub MCP: available

## iOS Tooling
- Xcode: 26.4.1 (Build 17E202)
- Swift: 6.3.1
- xcodebuild: available
- xcodegen: 2.45.4 (installed via brew)
- Simulators: iPhone 17 Pro, iPhone 17 Pro Max, iPhone 17e, iPhone Air, iPhone 17, iPad Pro/Air/mini
- Build target: arm64-apple-macosx26.0
- Tests: unit tests viable; UI tests viable

## LLM / Local AI
- Ollama: installed, not running
- Ollama models: qwen3.5:9b, llama3.1:8b, yi:latest, x/flux2-klein:latest
- ANTHROPIC_API_KEY: NOT SET
- OPENAI_API_KEY: NOT SET
- Decision: OllamaExtractionEngine (qwen3.5:9b default) + RuleBasedMemoryExtractionEngine fallback

## Backend / Local Service
- Python: 3.14.4
- uv: 0.11.6
- FastAPI: available via uv
- SQLite: 3.51.0
- Local port: will use 8765

## GitHub / CI
- .github/workflows: created
- Push: will work after remote creation
- Issues: enabled by default

## Obsidian / Vault
- No Obsidian vault configured
- Default: ./MnemoVault

## Secrets
- No API keys found
- .env.example will be created
- .env in .gitignore
