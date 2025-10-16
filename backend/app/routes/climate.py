# backend/app/routes/climate.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app import database
from app.models.user import User
from app.services.weather_service import get_weather
from app.utils.auth_utils import get_current_user

router = APIRouter()

@router.get("/predict")
def predict_weather(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    city = current_user.location
    weather_data = get_weather(city)

    # Error handling
    if "error" in weather_data:
        return {"msg": weather_data["error"]}

    # Return the full weather data including forecast
    return weather_data
