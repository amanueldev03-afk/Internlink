from pydantic import BaseModel


class Settings(BaseModel):
    app_name: str = 'InternLink AI Service'
    app_host: str = '0.0.0.0'
    app_port: int = 8000
    model_path: str = './models'
    log_level: str = 'INFO'


settings = Settings()
