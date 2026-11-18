from pydantic import BaseModel


class InternshipInput(BaseModel):
    title: str
    description: str
