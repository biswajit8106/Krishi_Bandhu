from fastapi import APIRouter, Form, Depends
from sqlalchemy.orm import Session
from ..services.crop_disease_service import crop_disease_service
from ..models.user import User
from ..models.irrigation import IrrigationEvent
from ..database import get_db
from ..utils.auth_utils import get_current_user

router = APIRouter()

@router.post("/predict")
async def predict_disease(
    crop_type: str = Form(...),
    file: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Make prediction using the service with base64 image data
        result = crop_disease_service.predict(crop_type.lower(), file)

        # Log the prediction as an event for recent activities
        if "predicted_class" in result and "confidence" in result:
            disease_name = result["predicted_class"]
            confidence = result["confidence"]
            details = f"Disease prediction for {crop_type.title()}: {disease_name} ({confidence:.1f}% confidence)"

            # Create event record
            event = IrrigationEvent(
                user_id=current_user.id,
                event_type="prediction_saved",
                details=details
            )
            db.add(event)
            db.commit()

        return {"crop_type": crop_type, **result}
    except Exception as e:
        return {"error": str(e)}

@router.get("/crops")
async def get_available_crops():
    crops = list(crop_disease_service.models.keys())
    return {"crops": crops}
