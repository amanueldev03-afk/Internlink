"""Security-related helpers for the AI service."""


def validate_api_key(api_key: str | None) -> bool:
    return api_key is not None and api_key.strip() != ''
