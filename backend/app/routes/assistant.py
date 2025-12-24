# assistant.py
import os
import io
import uuid
import sqlite3
import asyncio
import httpx
from typing import Optional
from fastapi import APIRouter, Depends, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
import speech_recognition as sr
from pydub import AudioSegment
from gtts import gTTS
from groq import Groq
from app import config, database
from app.utils.auth_utils import get_current_user
from app.models.user import User
from app.models.assistant_query import AssistantQuery
from app.services.weather_service import get_weather, get_weather_by_coords
from sqlalchemy.orm import Session
from datetime import datetime

router = APIRouter(prefix="/assistant", tags=["Assistant"])

# -----------------------------
# CONFIG / KEYS
# -----------------------------
GROQ_API_KEY = os.getenv("GROQ_API_KEY", config.GROQ_API_KEY)
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", None)  # optional provider
groq_client = Groq(api_key=GROQ_API_KEY)

# -----------------------------
# LANGUAGE MAP (backend validate)
# -----------------------------
LANGUAGE_MAP = {
    'en': 'en', 'hi': 'hi', 'kn': 'kn', 'te': 'te', 'ta': 'ta', 'mr': 'mr',
    'gu': 'gu', 'bn': 'bn', 'pa': 'pa', 'ml': 'ml', 'or': 'or', 'ur': 'ur'
}

# -----------------------------
# TRANSLATION CACHE (sqlite simple)
# -----------------------------
CACHE_DB = 'translation_cache.db'

def init_cache():
    conn = sqlite3.connect(CACHE_DB)
    conn.execute('''CREATE TABLE IF NOT EXISTS translations (key TEXT PRIMARY KEY, result TEXT, created INTEGER)''')
    conn.commit()
    conn.close()

def cache_get(key: str) -> Optional[str]:
    conn = sqlite3.connect(CACHE_DB)
    cur = conn.execute('SELECT result FROM translations WHERE key=?', (key,))
    row = cur.fetchone()
    conn.close()
    return row[0] if row else None

def cache_set(key: str, result: str):
    conn = sqlite3.connect(CACHE_DB)
    conn.execute('REPLACE INTO translations (key,result,created) VALUES (?,?,?)', (key, result, int(datetime.utcnow().timestamp())))
    conn.commit()
    conn.close()

async def translate(text: str, source: str, target: str) -> str:
    """
    Translate with cache -> external MyMemory fallback.
    """
    init_cache()
    key = f"{source}:{target}:{text}"
    cached = cache_get(key)
    if cached:
        return cached
    # call MyMemory free API (note: escape)
    try:
        url = f"https://api.mymemory.translated.net/get?q={httpx.utils.quote(text)}&langpair={source}|{target}"
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(url)
            translated = r.json().get("responseData", {}).get("translatedText")
            translated = translated or text
            cache_set(key, translated)
            return translated
    except Exception:
        return text

# -----------------------------
# GROQ ASK (LLM)
# -----------------------------
async def ask_groq(msg: str) -> str:
    prompt = f"""
You are KrishiBandhu Smart Assistant, an AI assistant specialized in agriculture and farming.
You help farmers with crop management, irrigation scheduling, weather information, disease detection, and farming advice.
IMPORTANT: Provide direct, practical farming advice. Use numbers and short actionable steps where possible.

User message:
{msg}

Provide a direct response about farming and agriculture:
"""
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content
    except Exception as e:
        print("ask_groq error:", e)
        return "Sorry, I couldn't process your request right now. Please try again later."

# -----------------------------
# AUDIO CONVERSION FOR STT
# -----------------------------
def convert_audio_for_stt(audio_bytes: bytes) -> sr.AudioData:
    """
    Convert arbitrary audio bytes -> 16kHz mono WAV bytes and return sr.AudioData.
    """
    try:
        seg = AudioSegment.from_file(io.BytesIO(audio_bytes))
        seg = seg.set_frame_rate(16000).set_channels(1).set_sample_width(2)
        buf = io.BytesIO()
        seg.export(buf, format="wav")
        wav_bytes = buf.getvalue()
        return sr.AudioData(wav_bytes, sample_rate=16000, sample_width=2)
    except Exception as e:
        print("convert_audio_for_stt fallback:", e)
        # as last resort, pass bytes assuming WAV 16k
        return sr.AudioData(audio_bytes, sample_rate=16000, sample_width=2)

# -----------------------------
# TTS: provider layer (OpenAI optional) with gTTS fallback
# -----------------------------
def get_tts_language(lang: str) -> str:
    return LANGUAGE_MAP.get(lang.lower(), 'en')

def generate_audio(text: str, lang: str) -> Optional[str]:
    """
    Primary fallback TTS: gTTS -> saves to static/audio and returns relative path like 'audio/<file>.mp3'
    """
    try:
        os.makedirs("static/audio", exist_ok=True)
        fname = f"audio_{uuid.uuid4().hex}.mp3"
        path = os.path.join("static", "audio", fname)
        tts_lang = get_tts_language(lang)
        tts = gTTS(text=text, lang=tts_lang, slow=False)
        tts.save(path)
        if os.path.exists(path):
            return f"audio/{fname}"
        return None
    except Exception as e:
        print("gTTS generate_audio error:", e)
        return None

async def generate_audio_with_provider(text: str, lang: str) -> Optional[str]:
    """
    Try provider (OpenAI Realtime/other) if configured, otherwise fallback to gTTS.
    (Pseudo-implementation — integrate actual provider SDK if available)
    """
    if OPENAI_API_KEY:
        try:
            # PSEUDO: call OpenAI TTS, save result to static/audio/... and return relative path
            # Implementer: plug in your OpenAI TTS code here.
            pass
        except Exception as e:
            print("OpenAI TTS failed:", e)
    return generate_audio(text, lang)

# -----------------------------
# Weather helpers
# -----------------------------
def is_weather_query(message: str) -> bool:
    weather_keywords = [
        'weather', 'temperature', 'rain', 'forecast', 'climate',
        'sunny', 'cloudy', 'wind', 'humidity', 'precipitation',
        'मौसम', 'तापमान', 'बारिश', 'पूर्वानुमान', 'farming weather'
    ]
    ml = message.lower()
    return any(k in ml for k in weather_keywords)

def format_weather_response(weather_data: dict, user_location: str) -> str:
    if not weather_data or "error" in weather_data:
        err = weather_data.get('error') if isinstance(weather_data, dict) else None
        return f"Sorry, I couldn't fetch weather data for {user_location}. {err or ''}"
    forecast = weather_data.get("forecast", [])
    response = f"Here's the current weather in {user_location}:\n\n"
    response += f"🌡️ Temperature: {weather_data.get('temperature', 'N/A')}°C\n"
    response += f"🌤️ Condition: {weather_data.get('condition', 'N/A')}\n"
    response += f"💨 Wind: {weather_data.get('wind_speed', 'N/A')} km/h\n"
    response += f"💧 Humidity: {weather_data.get('humidity', 'N/A')}%\n"
    if forecast:
        response += f"🌧️ Chance of Rain: {forecast[0].get('precipitation', 0)}%\n\n"
    if forecast:
        response += "📅 3-Day Forecast:\n"
        for i, day in enumerate(forecast[:3]):
            day_name = day.get('day', f'Day {i+1}')
            high = day.get('high_temp', 'N/A')
            low = day.get('low_temp', 'N/A')
            cond = day.get('condition', 'N/A')
            precip = day.get('precipitation', 'N/A')
            response += f"{day_name}: {cond}, {high}°C/{low}°C, {precip}% rain chance\n"
    # simple tips
    temp = weather_data.get('temperature', 25)
    precip = forecast[0].get('precipitation', 0) if forecast else 0
    response += "\n💡 Farming Tips: "
    try:
        temp = float(temp)
    except Exception:
        temp = 25
    if temp < 15:
        response += "Cold weather - protect sensitive crops from frost."
    elif temp > 35:
        response += "Hot weather - ensure adequate irrigation and shade for crops."
    elif precip > 50:
        response += "High chance of rain - prepare for waterlogging and fungal diseases."
    else:
        response += "Good weather conditions for most farming activities."
    return response

# -----------------------------
# Request models & endpoints
# -----------------------------
class ChatRequest(BaseModel):
    message: str
    language: str = "en"

@router.post("/chat")
async def assistant_chat(req: ChatRequest, user: User = Depends(get_current_user)):
    # normalize language
    lang = (req.language or "en").lower()
    if lang not in LANGUAGE_MAP:
        lang = "en"

    user_input = req.message or ""
    original_input = user_input.lower()

    # translate to English for LLM if needed
    en_input = await translate(user_input, lang, "en") if lang != "en" else user_input

    is_weather = is_weather_query(original_input) or is_weather_query(en_input)

    if is_weather:
        # try coordinates if present in user model
        user_location_str = str(getattr(user, "location", None) or "Unknown")
        # If user has lat/lon fields, use them:
        lat = getattr(user, "latitude", None)
        lon = getattr(user, "longitude", None)
        if lat and lon:
            weather_data = get_weather_by_coords(lat, lon)
            resolved_name = f"{lat},{lon}"
        else:
            weather_data = get_weather(user_location_str)
            resolved_name = user_location_str
        groq_output = format_weather_response(weather_data, resolved_name)
    else:
        groq_output = await ask_groq(en_input)

    final_output = await translate(groq_output, "en", lang) if lang != "en" else groq_output

    # Save to database (safe)
    db = database.SessionLocal()
    try:
        assistant_query = AssistantQuery(
            user_id=user.id,
            query_type="text",
            user_input=user_input,
            assistant_response=final_output,
            language=lang,
            audio_url=None
        )
        db.add(assistant_query)
        db.commit()
    except Exception as e:
        print("DB save error:", e)
        db.rollback()
    finally:
        db.close()

    return {"input": user_input, "response": final_output}

@router.post("/voice")
async def assistant_voice(
    file: UploadFile = File(...),
    language: str = Form("en"),
    user: User = Depends(get_current_user)
):
    language = (language or "en").lower()
    if language not in LANGUAGE_MAP:
        language = "en"

    audio_bytes = await file.read()
    recognizer = sr.Recognizer()
    user_text = "Sorry, I couldn't understand the audio."

    try:
        audio_data = convert_audio_for_stt(audio_bytes)
        user_text = recognizer.recognize_google(audio_data, language=language)
        print("DEBUG: speech recognized:", user_text)
    except sr.UnknownValueError:
        user_text = "Sorry, I couldn't understand the audio."
    except sr.RequestError as e:
        user_text = f"Sorry, speech recognition service error: {e}"
    except Exception as e:
        user_text = f"Sorry, error processing audio: {e}"

    original_text = (user_text or "").lower()
    en_text = await translate(user_text, language, "en") if language != "en" else user_text

    is_weather = is_weather_query(original_text) or is_weather_query(en_text)

    if is_weather:
        user_location_str = str(getattr(user, "location", None) or "Unknown")
        lat = getattr(user, "latitude", None)
        lon = getattr(user, "longitude", None)
        if lat and lon:
            weather_data = get_weather_by_coords(lat, lon)
            ai_en = format_weather_response(weather_data, f"{lat},{lon}")
        else:
            weather_data = get_weather(user_location_str)
            ai_en = format_weather_response(weather_data, user_location_str)
    else:
        ai_en = await ask_groq(en_text)

    final_response = await translate(ai_en, "en", language) if language != "en" else ai_en

    # Generate TTS (async provider layer)
    audio_rel_path = await generate_audio_with_provider(final_response, language)
    audio_url = f"/static/{audio_rel_path}" if audio_rel_path else None

    # Save to DB
    db = database.SessionLocal()
    try:
        assistant_query = AssistantQuery(
            user_id=user.id,
            query_type="voice",
            user_input=user_text,
            assistant_response=final_response,
            language=language,
            audio_url=audio_url
        )
        db.add(assistant_query)
        db.commit()
    except Exception as e:
        print("DB save error:", e)
        db.rollback()
    finally:
        db.close()

    return {
        "user_voice_text": user_text,
        "response": final_response,
        "audio_url": audio_url
    }
