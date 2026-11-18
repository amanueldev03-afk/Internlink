from pydantic import BaseModel


class CVInput(BaseModel):
    text: str
