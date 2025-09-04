# backend/app/services/weather_service.py

import requests
from app import config  # yahan SECRET_KEY ya API_KEY rakhe hain

def get_weather(city: str):
    """
    Fetch current weather for a city using OpenWeatherMap API.
    Returns a dictionary. Always safe (never returns None).
    """
    try:
        # Step 1: Get coordinates using Geocoding API
        geo_url = f"http://api.openweathermap.org/geo/1.0/direct?q={city}&limit=1&appid={config.WEATHER_API_KEY}"
        geo_resp = requests.get(geo_url, timeout=10)
        geo_data = geo_resp.json()
        
        if not geo_data:
            return {"error": "City not found"}
        
        lat = geo_data[0]["lat"]
        lon = geo_data[0]["lon"]
        
        # Step 2: Get current weather using One Call API
        weather_url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&units=metric&appid={config.WEATHER_API_KEY}"
        weather_resp = requests.get(weather_url, timeout=10)
        weather_data = weather_resp.json()
        
        if weather_data.get("cod") != 200:
            return {"error": weather_data.get("message", "Unable to fetch weather")}
        
        return weather_data
    
    except requests.RequestException:
        return {"error": "Unable to connect to weather service"}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}"}
