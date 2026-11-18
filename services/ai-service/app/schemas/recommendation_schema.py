from pydantic import BaseModel


class RecommendationOutput(BaseModel):
    recommendations: list[str]
