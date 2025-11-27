from fastapi import APIRouter, Depends, Body, HTTPException
from typing import Any, Dict
import os
import requests

from app import config
from app.utils.auth_utils import get_current_user
from app.models.user import User
from app.services import generative_service

router = APIRouter(prefix="/assistant", tags=["Assistant"])


def _simple_fallback_reply(message: str) -> str:
    m = (message or '').lower()
    if not m:
        return "Hello — how can I help you with your farm today?"
    if 'irrig' in m or 'water' in m:
        return "I can generate an irrigation plan for you. Send type='irrigation' with data including crop_type, soil_type, area and optional weather/prediction to `POST /assistant/chat`."
    if 'disease' in m or 'pest' in m or 'leaf' in m:
        return "For crop disease checks, please use the disease prediction endpoint with an image: `POST /disease/predict` (form fields `crop_type` and `file`)."
    if 'weather' in m or 'forecast' in m:
        return "You can get weather predictions from `/climate/predict`. Provide your location in your profile or in the request." 
    # generic fallback
    return "Sorry, I don't fully understand. You can ask me to generate irrigation plans, check disease predictions, or fetch weather."


@router.post("/chat")
def assistant_chat(payload: Dict[str, Any] = Body(...), user: User = Depends(get_current_user)):
    """Generic assistant endpoint.

    Payload fields:
    - `type`: 'chat' (default) or 'irrigation'
    - `message`: chat text (for 'chat')
    - `data`: dict passed to irrigation planner (for 'irrigation')
    """
    typ = payload.get('type', 'chat')

    if typ == 'irrigation':
        data = payload.get('data', {})
        try:
            plan = generative_service.generate_irrigation_plan(data, user)
            return {"type": "irrigation_plan", "plan": plan}
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    # default: chat
    message = payload.get('message', '')

    # If a generative API key is present, attempt to call external generative endpoint
    if config.GEMINI_API_KEY:
        try:
            url = os.environ.get('GEN_API_URL') or 'https://generativeapi.example.com/v1/generate'
            headers = {'Authorization': f'Bearer {config.GEMINI_API_KEY}', 'Content-Type': 'application/json'}
            body = {'prompt': message, 'max_tokens': 800}
            resp = requests.post(url, json=body, headers=headers, timeout=10)
            data = resp.json()
            text = data.get('text') or data.get('output') or data.get('response') or ''
            if not text and isinstance(data, dict):
                # fallback to returning structured data as a string
                text = str(data)
            return {"type": "chat", "reply": text}
        except Exception:
            # swallow and fallback to simple reply
            pass

    # fallback reply
    reply = _simple_fallback_reply(message)
    return {"type": "chat", "reply": reply}
