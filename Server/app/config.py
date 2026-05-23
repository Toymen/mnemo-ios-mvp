from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    server_port: int = 8765
    ollama_host: str = "http://localhost:11434"
    ollama_model: str = "qwen3.5:9b"
    vault_path: str = "./MnemoVault"
    database_url: str = "sqlite:///./mnemo.db"

    class Config:
        env_prefix = "MNEMO_"


settings = Settings()
