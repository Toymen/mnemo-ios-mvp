"""Mnemo local backend — FastAPI skeleton.

Not required for the iOS app. iOS uses Swift services directly.
This service is a future enhancement path for cross-device or desktop use.
"""
from fastapi import FastAPI
from .config import settings

app = FastAPI(title="Mnemo", version="0.1.0")


@app.get("/health")
async def health():
    return {"status": "ok", "version": "0.1.0"}
