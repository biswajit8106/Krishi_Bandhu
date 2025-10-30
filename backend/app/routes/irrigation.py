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
    # data expected to contain crop_type, soil_type, area, irrigation_method and optionally district/village
    crop_type = data.get('crop_type')
    soil_type = data.get('soil_type')
    area = data.get('area')
    irrigation_method = data.get('irrigation_method')

    # Fetch weather for the user's location (prefer profile values then incoming data)
    city = data.get('village') or data.get('district') or getattr(user, 'location', None) or getattr(user, 'village', None) or getattr(user, 'district', None)
    weather = get_weather(city) if city else {}

    # Prepare input data
    input_data = {
        "district": data.get('district') or getattr(user, 'district', None),
        "village": data.get('village') or getattr(user, 'village', None),
        "crop_type": crop_type,
        "soil_type": soil_type,
        "area": area,
        "irrigation_method": irrigation_method,
        "weather": weather
    }
    try:
        prediction = irrigation_model_service.predict(input_data)
        # Generate day-wise water requirements
        day_wise_payload = {
            'prediction': prediction,
            'weather': weather,
            'crop_type': crop_type,
            'soil_type': soil_type
        }
        day_wise_requirements = generative_service.generate_day_wise_water_requirements(day_wise_payload)
        # return prediction, weather, and day-wise requirements for UI
        return {"prediction": prediction, "weather": weather, "day_wise_requirements": day_wise_requirements}
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
    items = db.query(irrigation_models.IrrigationEvent).filter_by(user_id=user.id).order_by(irrigation_models.IrrigationEvent.timestamp.desc()).limit(20).all()
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
