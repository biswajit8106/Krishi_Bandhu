# backend/app/routes/profile.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app import database
from app.models.user import User
from app.models.irrigation import IrrigationEvent
from app.models.assistant_query import AssistantQuery
from app.models import CropPrediction
from datetime import datetime
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
    # Aggregate recent items from irrigation events, assistant queries and disease predictions
    irri_events = db.query(IrrigationEvent).filter(
        IrrigationEvent.user_id == current_user.id
    ).all()

    assistant_items = db.query(AssistantQuery).filter(
        AssistantQuery.user_id == current_user.id
    ).all()

    disease_preds = db.query(CropPrediction).filter(
        CropPrediction.user_id == current_user.id
    ).all()

    combined = []

    for e in irri_events:
        try:
            ts = e.timestamp
        except Exception:
            ts = None
        combined.append({
            "id": f"irrigation-{e.id}",
            "type": "irrigation",
            "title": e.event_type,
            "details": e.details,
            "meta": {"water_liters": e.water_liters},
            "timestamp": ts
        })

    for q in assistant_items:
        combined.append({
            "id": f"assistant-{q.id}",
            "type": "assistant",
            "title": q.query_type,
            "details": q.user_input,
            "meta": {"response_preview": (q.assistant_response[:200] if q.assistant_response else None, )},
            "timestamp": q.created_at
        })

    for p in disease_preds:
        combined.append({
            "id": f"disease-{p.id}",
            "type": "disease",
            "title": p.predicted_class if hasattr(p, 'predicted_class') else 'disease_prediction',
            "details": getattr(p, 'details', None) or '',
            "meta": {"crop_type": getattr(p, 'crop_type', None)},
            "timestamp": getattr(p, 'created_at', None)
        })

    # sort by timestamp descending and limit
    def _ts(x):
        return x.get('timestamp') or datetime.utcnow()

    combined_sorted = sorted(combined, key=_ts, reverse=True)
    latest = combined_sorted[:10]

    # isoformat timestamps where possible
    for item in latest:
        ts = item.get('timestamp')
        try:
            if ts is not None:
                item['timestamp'] = ts.isoformat()
        except Exception:
            item['timestamp'] = None

    return {"activities": latest}
