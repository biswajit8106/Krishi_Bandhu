# Accept JSON body
from fastapi import APIRouter, Depends, HTTPException, Body
from typing import List
from sqlalchemy.orm import Session
import csv
import os

# Use package-relative imports
from ..services.irrigation_model_service import IrrigationModelService
from ..services.weather_service import get_weather
from ..services import generative_service
from ..models.user import User
from ..models import irrigation as irrigation_models
from ..database import get_db
from ..utils.auth_utils import get_current_user

router = APIRouter()

# Load model once (update path as needed)
irrigation_model_service = IrrigationModelService("x:/KrishiBandhu/Training/irrigation/irrigation_model.pt")

# Helper to read training CSV for metadata (crop and soil types)
_metadata_cache = {}
def _load_metadata():
    if _metadata_cache:
        return _metadata_cache
    csv_path = os.path.abspath(r"x:/KrishiBandhu/Training/irrigation/dataset/irrigation.csv")
    crops = set()
    soils = set()
    try:
        with open(csv_path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for r in reader:
                c = r.get('Crop_Type') or r.get('CropType') or r.get('Crop')
                s = r.get('Soil_Type') or r.get('SoilType')
                if c:
                    crops.add(c.strip())
                if s:
                    soils.add(s.strip())
    except Exception:
        # fallback to a small set if file not present
        crops = {"Rice", "Wheat", "Maize", "Vegetables", "Orchard"}
        soils = {"Sandy Loam", "Clay Loam", "Alluvial Soil", "Black Soil"}

    _metadata_cache['crops'] = sorted(list(crops))
    _metadata_cache['soils'] = sorted(list(soils))
    return _metadata_cache


@router.post("/predict_irrigation")
def predict_irrigation(
    data: dict = Body(...),
    user: User = Depends(get_current_user),
):
    """
    Enhanced irrigation prediction using:
    - IoT sensor data: soil_moisture, temperature, humidity
    - Weather API: rainfall, sunlight, wind_speed
    - Manual input: crop_type, soil_type, field_area
    """
    try:
        # Manual inputs
        crop_type = data.get('crop_type')
        soil_type = data.get('soil_type')
        field_area_hectare = float(data.get('field_area_hectare', 1.0))
        
        # Get user location
        city = data.get('village') or data.get('district') or getattr(user, 'location', None) or getattr(user, 'village', None) or getattr(user, 'district', None)
        
        # Fetch weather data from weather API
        weather = get_weather(city) if city else {}
        rainfall_mm = float(weather.get('precipitation', 0) or 0)
        sunlight_hours = float(weather.get('sunlight_hours', 8) or 8)  # Default 8 hours
        wind_speed_kmh = float(weather.get('wind_speed', 5) or 5)  # Default 5 km/h
        
        # Fetch IoT sensor data
        iot_response = requests.get(THINGSPEAK_URL, timeout=10)
        iot_data = iot_response.json()
        
        # Default IoT values
        soil_moisture = 50.0
        temperature_c = 25.0
        humidity = 60.0
        
        # Parse IoT data if available
        if iot_data.get('feeds') and len(iot_data.get('feeds', [])) > 0:
            latest = iot_data['feeds'][0]
            try:
                soil_moisture = float(latest.get('field1') or 50)
            except (ValueError, TypeError):
                soil_moisture = 50
            try:
                temperature_c = float(latest.get('field2') or 25)
            except (ValueError, TypeError):
                temperature_c = 25
            try:
                humidity = float(latest.get('field3') or 60)
            except (ValueError, TypeError):
                humidity = 60
        
        # Simple encoding for categorical variables (you may need to update based on your model)
        def encode_soil_type(soil_type_str):
            """Encode soil type to numeric value"""
            soil_mapping = {
                'Sandy Loam': 0,
                'Clay Loam': 1,
                'Alluvial Soil': 2,
                'Black Soil': 3,
                'Red Soil': 4,
                'Laterite Soil': 5,
                'Gravelly Loam': 6,
                'Mixed Loam Soil': 7
            }
            return soil_mapping.get(soil_type_str, 0)
        
        def encode_crop_type(crop_type_str):
            """Encode crop type to numeric value"""
            crop_mapping = {
                'Rice': 0, 'Wheat': 1, 'Maize': 2, 'Vegetables': 3, 'Orchard': 4,
                'Barley': 5, 'Urad': 6, 'Jackfruit': 7, 'Ragi': 8, 'Millet': 9,
                'Tea': 10, 'Gram': 11, 'Brinjal': 12, 'Soybean': 13, 'Mango': 14,
                'Ladyfinger': 15, 'Moong': 16, 'Papaya': 17, 'Litchi': 18, 'Sugarcane': 19,
                'Groundnut': 20, 'Cabbage': 21, 'Sunflower': 22, 'Potato': 23, 'Mustard': 24,
                'Arhar': 25, 'Onion': 26, 'Cashew nut': 27, 'Cauliflower': 28, 'Chilli': 29,
                'Tomato': 30, 'Guava': 31
            }
            return crop_mapping.get(crop_type_str, 0)
        
        def encode_season(season_str):
            """Encode season to numeric value"""
            season_mapping = {
                'Kharif': 0,
                'Rabi': 1,
                'Summer': 2
            }
            return season_mapping.get(season_str, 0)
        
        # Get season from data or infer from current month
        season = data.get('season', 'Kharif')
        
        # Previous irrigation (default value - could be fetched from DB)
        previous_irrigation_mm = data.get('previous_irrigation_mm', 0)
        
        # Prepare complete input data for model service
        # Keys must match those expected by IrrigationModelService.predict()
        input_data = {
            "crop_type": crop_type,
            "soil_type": soil_type,
            "season": season,
            "soil_moisture": soil_moisture,
            "temperature": temperature_c,
            "humidity": humidity,
            "rainfall": rainfall_mm,
            "sunlight_hours": sunlight_hours,
            "wind_speed": wind_speed_kmh,
            "area": field_area_hectare,
            "previous_irrigation": previous_irrigation_mm,
            # Additional metadata for fallback/logging
            "weather": weather,
            "district": data.get('district') or getattr(user, 'district', None),
            "village": data.get('village') or getattr(user, 'village', None),
        }
        
        # Make prediction
        prediction = irrigation_model_service.predict(input_data)
        
        # Generate day-wise water requirements
        day_wise_payload = {
            'prediction': prediction,
            'weather': weather,
            'crop_type': crop_type,
            'soil_type': soil_type,
            'soil_moisture': soil_moisture,
            'temperature': temperature_c,
            'field_area': field_area_hectare
        }
        day_wise_requirements = generative_service.generate_day_wise_water_requirements(day_wise_payload)
        
        # Return comprehensive prediction result
        return {
            "success": True,
            "prediction": prediction,
            "weather": weather,
            "day_wise_requirements": day_wise_requirements,
            "sensor_data": {
                "soil_moisture": soil_moisture,
                "temperature": temperature_c,
                "humidity": humidity,
                "rainfall": rainfall_mm,
                "sunlight_hours": sunlight_hours,
                "wind_speed": wind_speed_kmh
            },
            "input_parameters": {
                "crop_type": crop_type,
                "soil_type": soil_type,
                "field_area_hectare": field_area_hectare,
                "season": season
            }
        }
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Error fetching sensor data: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/irrigation/metadata")
def irrigation_metadata():
    return _load_metadata()


@router.get("/irrigation/schedules")
def list_schedules(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    items = db.query(irrigation_models.IrrigationSchedule).filter_by(user_id=user.id).order_by(
        irrigation_models.IrrigationSchedule.date.asc(),
        irrigation_models.IrrigationSchedule.time.asc()
    ).all()
    return [{
        "id": s.id,
        "date": s.date,
        "time": s.time,
        "duration": s.duration,
        "is_enabled": s.is_enabled,
        "water_liters": s.water_liters
    } for s in items]


@router.post("/irrigation/schedules")
def create_schedule(payload: dict = Body(...), user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    time = payload.get('time')
    date = payload.get('date')  # YYYY-MM-DD
    duration = payload.get('duration') or ''
    is_enabled = payload.get('is_enabled', True)
    water_liters = payload.get('water_liters')
    s = irrigation_models.IrrigationSchedule(
        user_id=user.id,
        date=date,
        time=time,
        duration=duration,
        is_enabled=is_enabled,
        water_liters=water_liters
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return {"success": True, "id": s.id}


@router.get("/irrigation/events")
def list_events(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Only fetch irrigation-related events, exclude disease prediction events
    items = db.query(irrigation_models.IrrigationEvent).filter(
        irrigation_models.IrrigationEvent.user_id == user.id,
        irrigation_models.IrrigationEvent.event_type != "prediction_saved"
    ).order_by(irrigation_models.IrrigationEvent.timestamp.desc()).limit(20).all()
    out = []
    for e in items:
        out.append({"id": e.id, "type": e.event_type, "details": e.details, "water_liters": e.water_liters, "timestamp": e.timestamp.isoformat()})
    return out


@router.post("/irrigation/events")
def create_event(payload: dict = Body(...), user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    event_type = payload.get('event_type')
    details = payload.get('details')
    water_liters = payload.get('water_liters')
    e = irrigation_models.IrrigationEvent(user_id=user.id, event_type=event_type, details=details, water_liters=water_liters)
    db.add(e)
    # update water usage aggregated
    if water_liters:
        from datetime import datetime
        date = datetime.utcnow().strftime('%Y-%m-%d')
        wu = db.query(irrigation_models.WaterUsage).filter_by(user_id=user.id, date=date).first()
        if not wu:
            wu = irrigation_models.WaterUsage(user_id=user.id, date=date, liters=0.0)
            db.add(wu)
        wu.liters = (wu.liters or 0.0) + float(water_liters)
    db.commit()
    db.refresh(e)
    return {"success": True, "id": e.id}


@router.get("/irrigation/water_usage")
def get_water_usage(days: int = 7, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Return day-wise water usage for last `days`
    items = db.query(irrigation_models.WaterUsage).filter_by(user_id=user.id).order_by(irrigation_models.WaterUsage.date.desc()).limit(days).all()
    return [{"date": i.date, "liters": i.liters} for i in items]


@router.post("/irrigation/generate_schedule_ai")
def generate_schedule_ai(payload: dict = Body(...), user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # payload may contain prediction, weather, preferences
    try:
        plan = generative_service.generate_irrigation_plan(payload, user)
        # If plan returns schedules, persist them
        schedules = plan.get('schedules', []) if isinstance(plan, dict) else []
        created = []
        for s in schedules:
            sch = irrigation_models.IrrigationSchedule(
                user_id=user.id,
                date=s.get('date'),  # YYYY-MM-DD from planner
                time=s.get('time'),
                duration=s.get('duration', ''),
                water_liters=s.get('water_liters'),
                is_enabled=s.get('is_enabled', True)
            )
            db.add(sch)
            db.commit()
            db.refresh(sch)
            created.append({
                "id": sch.id,
                "date": sch.date,
                "time": sch.time,
                "duration": sch.duration,
                "water_liters": sch.water_liters
            })

        return {"success": True, "plan": plan, "created_schedules": created}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ========== IoT Real-Time Data Endpoints ==========
import requests
from datetime import datetime

THINGSPEAK_CHANNEL_ID = "3303453"
THINGSPEAK_API_KEY = "0WTD5DZ5ZFKG9GMX"
THINGSPEAK_URL = f"https://api.thingspeak.com/channels/{THINGSPEAK_CHANNEL_ID}/feeds.json?api_key={THINGSPEAK_API_KEY}&results=1"


@router.get("/irrigation/iot/realtime")
def get_iot_realtime_data(user: User = Depends(get_current_user)):
    """
    Fetch real-time IoT sensor data from ThingSpeak
    Returns: soil moisture, temperature, humidity, light, rain detection
    """
    try:
        response = requests.get(THINGSPEAK_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        if not data.get('feeds') or len(data.get('feeds', [])) == 0:
            # Return demo data if no real data available
            return {
                "success": False,
                "sensors": {
                    "soil_moisture": 65.5,
                    "soil_moisture_status": "Optimal",
                    "temperature": 28.3,
                    "temperature_status": "Optimal",
                    "humidity": 72.1,
                    "humidity_status": "Optimal",
                    "light": 650.0,
                    "light_status": "Good",
                    "rain_detected": False,
                    "rain_status": "No Rain"
                },
                "last_update": datetime.now().isoformat(),
                "message": "Demo data (no sensor data available)"
            }
        
        latest = data['feeds'][0]
        
        # Map ThingSpeak fields to sensor names with robust conversion
        try:
            soil_moisture = float(latest.get('field1') or 0)
        except (ValueError, TypeError):
            soil_moisture = 0
            
        try:
            temperature = float(latest.get('field2') or 0)
        except (ValueError, TypeError):
            temperature = 0
            
        try:
            humidity = float(latest.get('field3') or 0)
        except (ValueError, TypeError):
            humidity = 0
            
        try:
            rain = float(latest.get('field4') or 0)
        except (ValueError, TypeError):
            rain = 0
            
        try:
            light = float(latest.get('field5') or 0)
        except (ValueError, TypeError):
            light = 0
        
        # Determine sensor status based on thresholds
        def get_status(value, param):
            if param == "soil_moisture":
                if value < 30:
                    return "Too Dry ⚠️"
                elif value > 80:
                    return "Waterlogged"
                return "Optimal"
            elif param == "temperature":
                if value < 15:
                    return "Cold"
                elif value > 35:
                    return "Hot ⚠️"
                return "Optimal"
            elif param == "humidity":
                if value < 40:
                    return "Low"
                elif value > 85:
                    return "High"
                return "Optimal"
            elif param == "light":
                if value > 200:
                    return "Normal Light"
                return "Good"
            return "Normal"
        
        sensors = {
            "soil_moisture": round(soil_moisture, 1) if soil_moisture > 0 else soil_moisture,
            "soil_moisture_status": get_status(soil_moisture, "soil_moisture"),
            "temperature": round(temperature, 1) if temperature > 0 else temperature,
            "temperature_status": get_status(temperature, "temperature"),
            "humidity": round(humidity, 1) if humidity > 0 else humidity,
            "humidity_status": get_status(humidity, "humidity"),
            "light": round(light, 1) if light > 0 else light,
            "light_status": get_status(light, "light"),
            "rain_detected": rain < 2000,
            "rain_status": "Rain Detected 🌧️" if rain < 2000 else "No Rain"
        }
        
        return {
            "success": True,
            "sensors": sensors,
            "last_update": latest.get('created_at', datetime.now().isoformat()),
            "timestamp": datetime.now().isoformat()
        }
        
    except requests.RequestException as e:
        print(f"ThingSpeak API Error: {str(e)}")
        # Return demo data on error
        return {
            "success": False,
            "sensors": {
                "soil_moisture": 65.5,
                "soil_moisture_status": "Optimal",
                "temperature": 28.3,
                "temperature_status": "Optimal",
                "humidity": 72.1,
                "humidity_status": "Optimal",
                "light": 650.0,
                "light_status": "Good",
                "rain_detected": False,
                "rain_status": "No Rain"
            },
            "last_update": datetime.now().isoformat(),
            "message": f"API Error - showing demo data"
        }
    except Exception as e:
        print(f"Error processing IoT data: {str(e)}")
        # Return demo data on error
        return {
            "success": False,
            "sensors": {
                "soil_moisture": 65.5,
                "soil_moisture_status": "Optimal",
                "temperature": 28.3,
                "temperature_status": "Optimal",
                "humidity": 72.1,
                "humidity_status": "Optimal",
                "light": 650.0,
                "light_status": "Good",
                "rain_detected": False,
                "rain_status": "No Rain"
            },
            "last_update": datetime.now().isoformat(),
            "message": f"Error - showing demo data"
        }


@router.get("/irrigation/iot/predict")
def get_iot_based_prediction(user: User = Depends(get_current_user)):
    """
    Generate AI irrigation prediction based on real-time IoT data
    Analyzes current sensor readings and recommends irrigation action
    """
    try:
        # Get real-time data
        response = requests.get(THINGSPEAK_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Use demo data if no real data available
        if not data.get('feeds') or len(data.get('feeds', [])) == 0:
            soil_moisture = 65.5
            temperature = 28.3
            humidity = 72.1
            rain = 5000
            light = 650.0
        else:
            latest = data['feeds'][0]
            try:
                soil_moisture = float(latest.get('field1') or 50)
            except (ValueError, TypeError):
                soil_moisture = 50
                
            try:
                temperature = float(latest.get('field2') or 28)
            except (ValueError, TypeError):
                temperature = 28
                
            try:
                humidity = float(latest.get('field3') or 60)
            except (ValueError, TypeError):
                humidity = 60
                
            try:
                rain = float(latest.get('field4') or 0)
            except (ValueError, TypeError):
                rain = 0
                
            try:
                light = float(latest.get('field5') or 500)
            except (ValueError, TypeError):
                light = 500
        
        # Get user profile and location
        city = getattr(user, 'village', None) or getattr(user, 'district', None) or "Unknown"
        weather = get_weather(city) if city else {}
        
        # AI Logic for irrigation recommendation
        recommendation = ""
        urgency = "normal"
        reason = ""
        
        # Priority 1: Rain Detection
        if rain < 2000:
            recommendation = "⏸️ PAUSE IRRIGATION"
            urgency = "high"
            reason = "Rain detected. Skip irrigation to conserve water. Resume in 24-48 hours."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": True
            }
        
        # Priority 2: Soil Moisture Critical
        if soil_moisture < 25:
            recommendation = "🚨 URGENT: Start Irrigation NOW"
            urgency = "high"
            reason = f"Soil moisture critically low at {soil_moisture}%. Start deep watering immediately (30-45 min)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 3: Waterlogging Risk
        if soil_moisture > 85:
            recommendation = "✋ STOP IRRIGATION"
            urgency = "medium"
            reason = f"Soil moisture at {soil_moisture}%. Risk of waterlogging. Avoid watering for 2-3 days."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 4: Low Soil Moisture (Moderate)
        if soil_moisture < 40:
            recommendation = "⚠️ Schedule Irrigation Soon"
            urgency = "medium"
            reason = f"Soil moisture at {soil_moisture}%. Plan irrigation in next 12-24 hours (20-30 min watering)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 5: High Temperature
        if temperature > 35 and soil_moisture < 60:
            recommendation = "☀️ Increase Watering Frequency"
            urgency = "medium"
            reason = f"High temperature ({temperature}°C) with moderate soil moisture. Increase irrigation frequency (every 2-3 days)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 6: Low Humidity
        if humidity < 35 and soil_moisture < 55:
            recommendation = "💨 Increase Watering"
            urgency = "medium"
            reason = f"Low humidity ({humidity}%) increases evaporation. Water more frequently (every 3-4 days)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Optimal Conditions
        if 50 <= soil_moisture <= 75:
            recommendation = "✅ Conditions Optimal"
            urgency = "normal"
            reason = "All conditions favorable. Continue regular maintenance watering schedule."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Default
        recommendation = "📊 Monitor Conditions"
        urgency = "normal"
        reason = f"Soil moisture: {soil_moisture}%. Temp: {temperature}°C. Monitor for next 24 hours."
        
        return {
            "recommendation": recommendation,
            "urgency": urgency,
            "reason": reason,
            "soil_moisture": soil_moisture,
            "temperature": temperature,
            "rain_detected": False
        }
        
    except requests.RequestException as e:
        print(f"ThingSpeak Error: {str(e)}")
        return {
            "recommendation": "✅ Conditions Optimal",
            "urgency": "normal",
            "reason": "Using demo data. System is monitoring your farm."
        }
    except Exception as e:
        print(f"Error in prediction: {str(e)}")
        return {
            "recommendation": "✅ Conditions Optimal",
            "urgency": "normal",
            "reason": "Using demo data. System is monitoring your farm."
        }
        
        # Get user profile and location
        city = getattr(user, 'village', None) or getattr(user, 'district', None) or "Unknown"
        weather = get_weather(city) if city else {}
        
        # AI Logic for irrigation recommendation
        recommendation = ""
        urgency = "normal"
        reason = ""
        
        # Priority 1: Rain Detection
        if rain < 2000:
            recommendation = " PAUSE IRRIGATION"
            urgency = "high"
            reason = "Rain detected. Skip irrigation to conserve water. Resume in 24-48 hours."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": True
            }
        
        # Priority 2: Soil Moisture Critical
        if soil_moisture < 25:
            recommendation = " URGENT: Start Irrigation NOW"
            urgency = "high"
            reason = f"Soil moisture critically low at {soil_moisture}%. Start deep watering immediately (30-45 min)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 3: Waterlogging Risk
        if soil_moisture > 85:
            recommendation = " STOP IRRIGATION"
            urgency = "medium"
            reason = f"Soil moisture at {soil_moisture}%. Risk of waterlogging. Avoid watering for 2-3 days."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 4: Low Soil Moisture (Moderate)
        if soil_moisture < 40:
            recommendation = " Schedule Irrigation Soon"
            urgency = "medium"
            reason = f"Soil moisture at {soil_moisture}%. Plan irrigation in next 12-24 hours (20-30 min watering)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 5: High Temperature
        if temperature > 35 and soil_moisture < 60:
            recommendation = " Increase Watering Frequency"
            urgency = "medium"
            reason = f"High temperature ({temperature}°C) with moderate soil moisture. Increase irrigation frequency (every 2-3 days)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Priority 6: Low Humidity
        if humidity < 35 and soil_moisture < 55:
            recommendation = " Increase Watering"
            urgency = "medium"
            reason = f"Low humidity ({humidity}%) increases evaporation. Water more frequently (every 3-4 days)."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Optimal Conditions
        if 50 <= soil_moisture <= 75:
            recommendation = " Conditions Optimal"
            urgency = "normal"
            reason = "All conditions favorable. Continue regular maintenance watering schedule."
            return {
                "recommendation": recommendation,
                "urgency": urgency,
                "reason": reason,
                "soil_moisture": soil_moisture,
                "temperature": temperature,
                "rain_detected": False
            }
        
        # Default
        recommendation = " Monitor Conditions"
        urgency = "normal"
        reason = f"Soil moisture: {soil_moisture}%. Temp: {temperature}°C. Monitor for next 24 hours."
        
        return {
            "recommendation": recommendation,
            "urgency": urgency,
            "reason": reason,
            "soil_moisture": soil_moisture,
            "temperature": temperature,
            "rain_detected": False
        }
        
    except requests.RequestException as e:
        return {
            "recommendation": "Cannot fetch data",
            "urgency": "normal",
            "reason": f"IoT connection error: {str(e)}"
        }
    except Exception as e:
        return {
            "recommendation": "System error",
            "urgency": "normal",
            "reason": f"Prediction error: {str(e)}"
        }
