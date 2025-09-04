# backend/app/routes/climate.py

from fastapi import APIRouter, Query
from app.services.weather_service import get_weather

router = APIRouter()

@router.get("/predict")
def predict_weather(city: str = Query(..., description="Enter city name")):
    weather_data = get_weather(city)
    
    # Error handling
    if "error" in weather_data:
        return {"msg": weather_data["error"]}
    
    # Extract required info safely
    main_weather = weather_data.get("weather", [{}])[0].get("main", "Unknown")
    temp = weather_data.get("main", {}).get("temp", "Unknown")
    humidity = weather_data.get("main", {}).get("humidity", "Unknown")
    
    # Simple prediction logic
    if isinstance(humidity, (int, float)) and humidity > 80 and main_weather in ["Rain", "Clouds"]:
        prediction = "High chance of rainfall 🌧️"
    else:
        prediction = "Low chance of rainfall ☀️"
    
    return {
        "city": city,
        "temperature": temp,
        "humidity": humidity,
        "condition": main_weather,
        "prediction": prediction
    }
