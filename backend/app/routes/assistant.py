from fastapi import APIRouter, Depends, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
import httpx, os, uuid, io
from typing import Optional
from app import config, database
from app.utils.auth_utils import get_current_user
from app.models.user import User
from app.models.assistant_query import AssistantQuery
from app.services.weather_service import get_weather
import speech_recognition as sr
import wave
import io
from groq import Groq
from gtts import gTTS
from sqlalchemy.orm import Session

router = APIRouter(prefix="/assistant", tags=["Assistant"])

# -----------------------------
# API KEYS
# -----------------------------
GROQ_API_KEY = os.getenv("GROQ_API_KEY", config.GROQ_API_KEY)

groq_client = Groq(api_key=GROQ_API_KEY)


# -----------------------------
# FREE TRANSLATION
# -----------------------------
async def translate(text: str, source: str, target: str) -> str:
    url = f"https://api.mymemory.translated.net/get?q={text}&langpair={source}|{target}"
    try:
        async with httpx.AsyncClient() as client:
            r = await client.get(url)
            translated = r.json()["responseData"]["translatedText"]
            return translated if translated else text
    except:
        return text


# -----------------------------
# GROQ RESPONSE
# -----------------------------
async def ask_groq(msg: str) -> str:
    prompt = f"""
You are KrishiBandhu Smart Assistant, an AI assistant specialized in agriculture and farming.
You help farmers with crop management, irrigation scheduling, weather information, disease detection, and farming advice.

IMPORTANT INSTRUCTIONS:
- NEVER suggest language selections or translations
- NEVER mention language options like Hindi, Kannada, etc.
- NEVER ask about preferred languages
- ALWAYS provide direct, practical farming advice
- Focus ONLY on agriculture, crops, irrigation, weather, and farming practices
- Give specific, actionable recommendations

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
        print(f"Error in ask_groq: {e}")
        return "Sorry, I couldn't process your request right now. Please try again later."


# -----------------------------
# AUDIO FORMAT CONVERSION
# -----------------------------
def convert_audio_for_stt(audio_bytes: bytes) -> sr.AudioData:
    """Convert audio bytes to proper format for speech recognition"""
    try:
        # Try to convert using pydub if available, otherwise assume it's already WAV
        try:
            from pydub import AudioSegment
            # Convert to WAV format with proper parameters
            audio_segment = AudioSegment.from_file(io.BytesIO(audio_bytes))
            audio_segment = audio_segment.set_frame_rate(16000).set_channels(1)
            wav_buffer = io.BytesIO()
            audio_segment.export(wav_buffer, format="wav")
            wav_buffer.seek(0)
            wav_bytes = wav_buffer.read()

            # Create AudioData object
            return sr.AudioData(wav_bytes, 16000, 2)
        except ImportError:
            # Fallback: assume audio is already in correct format
            print("Warning: pydub not available, assuming audio is already 16kHz WAV")
            return sr.AudioData(audio_bytes, 16000, 2)
    except Exception as e:
        print(f"Error converting audio: {e}")
        raise


# -----------------------------
# LANGUAGE MAPPING FOR TTS
# -----------------------------
LANGUAGE_MAP = {
    'en': 'en',  # English
    'hi': 'hi',  # Hindi
    'kn': 'kn',  # Kannada
    'te': 'te',  # Telugu
    'ta': 'ta',  # Tamil
    'mr': 'mr',  # Marathi
    'gu': 'gu',  # Gujarati
    'bn': 'bn',  # Bengali
    'pa': 'pa',  # Punjabi
    'ml': 'ml',  # Malayalam
    'or': 'or',  # Odia
    'ur': 'ur',  # Urdu
    # Fallback to English for unsupported languages
}


def get_tts_language(lang: str) -> str:
    """Get the appropriate TTS language code, with fallback to English"""
    return LANGUAGE_MAP.get(lang.lower(), 'en')


# -----------------------------
# TTS Generator (gTTS)
# -----------------------------
def generate_audio(text: str, lang: str) -> Optional[str]:
    try:
        # Ensure the audio directory exists
        os.makedirs("static/audio", exist_ok=True)

        filename = f"audio_{uuid.uuid4().hex}.mp3"
        filepath = f"static/audio/{filename}"

        # Get appropriate language for TTS
        tts_lang = get_tts_language(lang)

        print(f"DEBUG: Generating audio for text: '{text[:50]}...' in language: {tts_lang}")

        tts = gTTS(text=text, lang=tts_lang, slow=False)
        tts.save(filepath)

        # Verify file was created
        if os.path.exists(filepath):
            print(f"DEBUG: Audio file created successfully: {filepath}")
            return f"audio/{filename}"  # Return relative path from static directory
        else:
            print(f"ERROR: Audio file was not created: {filepath}")
            return None

    except Exception as e:
        print(f"Error in generate_audio: {e}")
        return None


# -----------------------------
# WEATHER DETECTION AND RESPONSE
# -----------------------------
def is_weather_query(message: str) -> bool:
    """Check if the message is asking about weather"""
    weather_keywords = [
        'weather', 'temperature', 'rain', 'forecast', 'climate',
        'sunny', 'cloudy', 'wind', 'humidity', 'precipitation',
        'मौसम', 'तापमान', 'बारिश', 'पूर्वानुमान', 'farming weather'
    ]
    message_lower = message.lower()
    return any(keyword in message_lower for keyword in weather_keywords)


def format_weather_response(weather_data: dict, user_location: str) -> str:
    """Format weather data into a helpful farming-focused response"""
    if "error" in weather_data:
        return f"Sorry, I couldn't fetch weather data for {user_location}. {weather_data['error']}"

    forecast = weather_data.get("forecast", [])

    response = f"Here's the current weather in {user_location}:\n\n"
    response += f"🌡️ Temperature: {weather_data.get('temperature', 'N/A')}°C\n"
    response += f"🌤️ Condition: {weather_data.get('condition', 'N/A')}\n"
    response += f"💨 Wind: {weather_data.get('wind_speed', 'N/A')} km/h\n"
    response += f"💧 Humidity: {weather_data.get('humidity', 'N/A')}%\n"
    response += f"🌧️ Chance of Rain: {forecast[0].get('precipitation', 0) if forecast else 0}%\n\n"

    if forecast and len(forecast) > 0:
        response += "📅 3-Day Forecast:\n"
        for i, day in enumerate(forecast[:3]):
            day_name = day.get('day', f'Day {i+1}')
            high_temp = day.get('high_temp', 'N/A')
            low_temp = day.get('low_temp', 'N/A')
            condition = day.get('condition', 'N/A')
            precip = day.get('precipitation', 'N/A')
            response += f"{day_name}: {condition}, {high_temp}°C/{low_temp}°C, {precip}% rain chance\n"

    response += "\n💡 Farming Tips: "
    temp = weather_data.get('temperature', 25)
    precip_chance = forecast[0].get('precipitation', 0) if forecast else 0

    if temp < 15:
        response += "Cold weather - protect sensitive crops from frost."
    elif temp > 35:
        response += "Hot weather - ensure adequate irrigation and shade for crops."
    elif precip_chance > 50:
        response += "High chance of rain - prepare for waterlogging and fungal diseases."
    else:
        response += "Good weather conditions for most farming activities."

    return response


# -----------------------------
# TEXT CHAT ENDPOINT
# -----------------------------
class ChatRequest(BaseModel):
    message: str
    language: str = "en"


@router.post("/chat")
async def assistant_chat(req: ChatRequest, user: User = Depends(get_current_user)):
    lang = req.language
    user_input = req.message

    # Step 1: Check if this is a weather query (check both original and translated)
    original_input = user_input.lower()
    en_input = await translate(user_input, lang, "en")

    # Check both original and translated input for weather keywords
    is_weather = is_weather_query(original_input) or is_weather_query(en_input)

    if is_weather:
        # Fetch real weather data using user's location
        user_location_str = str(user.location) if user.location is not None else "Unknown"
        print(f"DEBUG: Weather query detected. User location: {user_location_str}")
        weather_data = get_weather(user_location_str)
        print(f"DEBUG: Weather data received: {weather_data}")
        groq_output = format_weather_response(weather_data, user_location_str)
        print(f"DEBUG: Formatted weather response: {groq_output}")
    else:
        # Step 2: Ask Groq for non-weather queries
        groq_output = await ask_groq(en_input)

    # Step 3: English → user language
    final_output = await translate(groq_output, "en", lang)

    response_data = {
        "input": user_input,
        "response": final_output
    }

    # Save query to database
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
        print(f"DEBUG: Saved text query to database for user {user.id}")
    except Exception as e:
        print(f"Error saving text query to database: {e}")
        db.rollback()
    finally:
        db.close()

    print(f"Assistant chat response: {response_data}")

    return response_data


# -----------------------------
# VOICE ASSISTANT ENDPOINT
# -----------------------------
@router.post("/voice")
async def assistant_voice(
    file: UploadFile = File(...),
    language: str = Form("en"),
    user: User = Depends(get_current_user)
):
    # Step 1: Save uploaded audio file
    audio_bytes = await file.read()

    # Step 2: Speech Recognition STT
    user_text = "Sorry, I couldn't understand the audio."  # Default value
    try:
        # Create a recognizer instance
        recognizer = sr.Recognizer()

        # Convert audio to proper format for speech recognition
        audio_data = convert_audio_for_stt(audio_bytes)

        # Recognize speech using Google Speech Recognition
        user_text = recognizer.recognize_google(audio_data, language=language)
        print(f"DEBUG: Speech recognized: {user_text}")
    except sr.UnknownValueError:
        user_text = "Sorry, I couldn't understand the audio."
        print("DEBUG: Speech recognition - unknown value error")
    except sr.RequestError as e:
        user_text = f"Sorry, speech recognition service error: {e}"
        print(f"DEBUG: Speech recognition request error: {e}")
    except Exception as e:
        user_text = f"Sorry, error processing audio: {e}"
        print(f"DEBUG: Speech recognition general error: {e}")

    # Step 3: Check if this is a weather query (check both original and translated)
    original_text = user_text.lower()
    en_text = await translate(user_text, language, "en")

    # Check both original and translated input for weather keywords
    is_weather = is_weather_query(original_text) or is_weather_query(en_text)

    if is_weather:
        # Fetch real weather data using user's location
        user_location_str = str(user.location) if user.location else "Unknown"
        print(f"DEBUG: Voice weather query detected. User location: {user_location_str}")
        weather_data = get_weather(user_location_str)
        print(f"DEBUG: Voice weather data received: {weather_data}")
        ai_en = format_weather_response(weather_data, user_location_str)
        print(f"DEBUG: Voice formatted weather response: {ai_en}")
    else:
        # Step 4: Groq answer for non-weather queries
        ai_en = await ask_groq(en_text)

    # Step 5: Back to user language
    final_response = await translate(ai_en, "en", language)

    # Step 6: Generate assistant voice output
    audio_path = generate_audio(final_response, language)

    response_data = {
        "user_voice_text": user_text,
        "response": final_response,
        "audio_url": f"/static/{audio_path}" if audio_path else None
    }

    # Step 7: Save query to database
    db = database.SessionLocal()
    try:
        assistant_query = AssistantQuery(
            user_id=user.id,
            query_type="voice",
            user_input=user_text,
            assistant_response=final_response,
            language=language,
            audio_url=f"/static/{audio_path}" if audio_path else None
        )
        db.add(assistant_query)
        db.commit()
        print(f"DEBUG: Saved voice query to database for user {user.id}")
    except Exception as e:
        print(f"Error saving voice query to database: {e}")
        db.rollback()
    finally:
        db.close()

    print(f"Assistant voice response: {response_data}")

    return response_data
