# backend/app/routes/profile.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app import database
from app.models.user import User
from app.models.irrigation import IrrigationEvent
from app.utils.auth_utils import get_current_user

router = APIRouter()

@router.get("/me")
def get_profile(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "phone": current_user.phone,
        "state": current_user.state,
        "district": current_user.district,
        "location": current_user.location,
        "language": current_user.language,
        "role": current_user.role,
        "profile_image": current_user.profile_image
    }

@router.put("/update")
def update_profile(
    name: str,
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.name = name
    db.commit()
    db.refresh(current_user)
    return {"msg": "Profile updated", "name": current_user.name}

@router.get("/recent-activities")
def get_recent_activities(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(get_current_user)
):
    # Fetch recent irrigation events for the user (both irrigation and disease predictions)
    events = db.query(IrrigationEvent).filter(
        IrrigationEvent.user_id == current_user.id
    ).order_by(IrrigationEvent.timestamp.desc()).limit(10).all()

    activities = []
    for event in events:
        activities.append({
            "id": event.id,
            "event_type": event.event_type,
            "details": event.details,
            "water_liters": event.water_liters,
            "timestamp": event.timestamp.isoformat()
        })

    return {"activities": activities}
