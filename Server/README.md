# Mnemo Server (Skeleton)

FastAPI backend skeleton. Not required for iOS MVP.

## Status: Skeleton only

The iOS app uses Swift services directly and does not call this server.
This is a future enhancement path.

## Running (when implemented)

```bash
cd Server
uv sync
uv run uvicorn app.main:app --port 8765
```

## Endpoints (planned)

- `GET /health`
- `POST /captures`
- `POST /extract`
- `GET /candidates`
- `POST /candidates/{id}/approve`
- `POST /candidates/{id}/reject`
- `GET /memories`
- `GET /projects`
- `POST /vault/export`
