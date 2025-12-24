# backend/app/services/weather_service.py

import requests
from datetime import datetime, timedelta
from app import config

def _get_forecast_day_name(index: int) -> str:
    """Get the day name for forecast (Today, Tomorrow, etc.)"""
    if index == 0:
        return "Today"
    elif index == 1:
        return "Tomorrow"
    else:
        now = datetime.now()
        target_date = now + timedelta(days=index)
        return target_date.strftime("%a")  # Abbreviated weekday, e.g., Mon, Tue

def _get_forecast_date(index: int) -> str:
    """Get the date string for forecast"""
    now = datetime.now()
    # Use timedelta instead of replace to avoid invalid day values
    target_date = now + timedelta(days=index)
    return f"{target_date.day}/{target_date.month}"

def get_weather(city: str):
    """
    Fetch comprehensive weather data for a city using WeatherAPI.com.
    Returns a dictionary with all required weather information.
    """
    try:
        # Fetch current weather and forecast in one request
        url = f"http://api.weatherapi.com/v1/forecast.json?q={city}&days=7&key={config.WEATHER_API_KEY}"
        resp = requests.get(url, timeout=10)
        data = resp.json()

        if "error" in data:
            return {"error": data["error"]["message"]}

        # Extract current weather data
        current = data.get("current", {})
        location = data.get("location", {})

        # Extract forecast data
        forecast_days = data.get("forecast", {}).get("forecastday", [])

        forecast = []
        for i, day in enumerate(forecast_days):
            day_data = day.get("day", {})
            forecast.append({
                "day": _get_forecast_day_name(i),
                "date": _get_forecast_date(i),
                "high_temp": round(day_data.get("maxtemp_c", 0), 1),
                "low_temp": round(day_data.get("mintemp_c", 0), 1),
                "condition": day_data.get("condition", {}).get("text", "Unknown"),
                "precipitation": round(day_data.get("daily_chance_of_rain", 0), 0),
            })

        # Sunrise and sunset from forecast (first day)
        if forecast_days:
            astro = forecast_days[0].get("astro", {})
            sunrise = astro.get("sunrise", "--")
            sunset = astro.get("sunset", "--")
        else:
            sunrise = "--"
            sunset = "--"

        # Moon phase - not directly available, set to unknown
        moon_phase = "Unknown"

        # UV index, dew point, feels like
        uv_index = current.get("uv", 0)
        dew_point = 0  # Not available in WeatherAPI.com free tier
        feels_like = round(current.get("feelslike_c", current.get("temp_c", 0)), 1)

        # Visibility
        visibility = round(current.get("vis_km", 10), 1)

        # Air quality - not available in free tier, set to unknown
        air_quality = "Unknown"

        # Alerts - check if available
        alerts = data.get("alerts", {}).get("alert", [])
        alert_title = alerts[0].get("headline") if alerts else None
        alert_description = alerts[0].get("desc") if alerts else None

        return {
            "city": location.get("name", city),
            "temperature": round(current.get("temp_c", 0), 1),
            "condition": current.get("condition", {}).get("text", "Unknown"),
            "humidity": current.get("humidity", 0),
            "wind_speed": round(current.get("wind_kph", 0) / 3.6, 1),  # Convert kph to m/s
            "pressure": current.get("pressure_mb", 0),
            "uv_index": uv_index,
            "visibility": visibility,
            "dew_point": dew_point,
            "feels_like": feels_like,
            "sunrise": sunrise,
            "sunset": sunset,
            "moon_phase": moon_phase,
            "air_quality": air_quality,
            "alert_title": alert_title,
            "alert_description": alert_description,
            "forecast": forecast,
            "prediction": "Weather data updated"
        }

    except requests.RequestException:
        return {"error": "Unable to connect to weather service"}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}"}

def get_weather_by_coords(lat: float, lon: float):
    """
    Fetch comprehensive weather data for coordinates using WeatherAPI.com.
    Returns a dictionary with all required weather information.
    """
    try:
        # Fetch current weather and forecast in one request
        url = f"http://api.weatherapi.com/v1/forecast.json?q={lat},{lon}&days=7&key={config.WEATHER_API_KEY}"
        resp = requests.get(url, timeout=10)
        data = resp.json()

        if "error" in data:
            return {"error": data["error"]["message"]}

        # Extract current weather data
        current = data.get("current", {})
        location = data.get("location", {})

        # Extract forecast data
        forecast_days = data.get("forecast", {}).get("forecastday", [])

        forecast = []
        for i, day in enumerate(forecast_days):
            day_data = day.get("day", {})
            forecast.append({
                "day": _get_forecast_day_name(i),
                "date": _get_forecast_date(i),
                "high_temp": round(day_data.get("maxtemp_c", 0), 1),
                "low_temp": round(day_data.get("mintemp_c", 0), 1),
                "condition": day_data.get("condition", {}).get("text", "Unknown"),
                "precipitation": round(day_data.get("daily_chance_of_rain", 0), 0),
            })

        # Sunrise and sunset from forecast (first day)
        if forecast_days:
            astro = forecast_days[0].get("astro", {})
            sunrise = astro.get("sunrise", "--")
            sunset = astro.get("sunset", "--")
        else:
            sunrise = "--"
            sunset = "--"

        # Moon phase - not directly available, set to unknown
        moon_phase = "Unknown"

        # UV index, dew point, feels like
        uv_index = current.get("uv", 0)
        dew_point = 0  # Not available in WeatherAPI.com free tier
        feels_like = round(current.get("feelslike_c", current.get("temp_c", 0)), 1)

        # Visibility
        visibility = round(current.get("vis_km", 10), 1)

        # Air quality - not available in free tier, set to unknown
        air_quality = "Unknown"

        # Alerts - check if available
        alerts = data.get("alerts", {}).get("alert", [])
        alert_title = alerts[0].get("headline") if alerts else None
        alert_description = alerts[0].get("desc") if alerts else None

        return {
            "city": location.get("name", f"{lat},{lon}"),
            "temperature": round(current.get("temp_c", 0), 1),
            "condition": current.get("condition", {}).get("text", "Unknown"),
            "humidity": current.get("humidity", 0),
            "wind_speed": round(current.get("wind_kph", 0) / 3.6, 1),  # Convert kph to m/s
            "pressure": current.get("pressure_mb", 0),
            "uv_index": uv_index,
            "visibility": visibility,
            "dew_point": dew_point,
            "feels_like": feels_like,
            "sunrise": sunrise,
            "sunset": sunset,
            "moon_phase": moon_phase,
            "air_quality": air_quality,
            "alert_title": alert_title,
            "alert_description": alert_description,
            "forecast": forecast,
            "prediction": "Weather data updated"
        }

    except requests.RequestException:
        return {"error": "Unable to connect to weather service"}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}"}
