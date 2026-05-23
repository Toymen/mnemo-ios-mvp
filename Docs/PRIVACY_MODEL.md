# Privacy Model

## Principles

1. **Local-first**: All data is stored on-device. No cloud sync.
2. **Consent-required**: No memory is ever created without explicit user approval.
3. **No telemetry**: No analytics, no crash reporting, no network calls by default.
4. **Transparent LLM use**: If Ollama is configured, calls go to localhost only.

## Data Flows

| Data | Where It Goes |
|------|--------------|
| Capture text | Local JSON (~/Documents/MnemoData/) |
| Memory candidates | Local JSON |
| Approved memories | Local JSON + optional Markdown vault |
| Voice audio | Processed locally; not stored |
| Transcriptions | Local only |

## Cloud LLM Warning

If a cloud LLM API key is configured, capture text will be sent to that provider.
The app warns users before enabling cloud LLM.
No keys are hardcoded; all via environment variables or app settings.

## Secrets

- Never commit `.env` or API keys
- `.env.example` shows available variables
- `.gitignore` excludes all secret files
