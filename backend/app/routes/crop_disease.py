from fastapi import APIRouter, Form, Depends
from sqlalchemy.orm import Session
from ..services.crop_disease_service import crop_disease_service
from ..models.user import User
from ..models import CropPrediction
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

        # Save prediction to history
        if "predicted_class" in result and "confidence" in result:
            disease_name = result["predicted_class"]
            confidence = result["confidence"]
            
            # Convert confidence to percentage if it's in 0-1 range
            try:
                conf_float = float(confidence) if confidence is not None else 0.0
                if conf_float <= 1.0:
                    conf_float = conf_float * 100.0
            except (TypeError, ValueError):
                conf_float = 0.0
            
            details = f"Disease prediction for {crop_type.title()}: {disease_name} ({conf_float:.1f}% confidence)"

            # store probabilities as JSON string where available
            try:
                import json
                prob_str = json.dumps(result.get("probabilities")) if result.get("probabilities") is not None else None
            except Exception:
                prob_str = None

            pred = CropPrediction(
                user_id=current_user.id,
                crop_type=crop_type.lower(),
                predicted_class=disease_name,
                confidence=conf_float,
                probabilities=prob_str,
                recommendation=result.get("recommendation") or (result.get("recommendation") if isinstance(result.get("recommendation"), str) else None),
                prevention=result.get("prevention"),
                details=details
            )
            db.add(pred)
            db.commit()

        return {"crop_type": crop_type, **result}
    except Exception as e:
        return {"error": str(e)}


@router.get("/history")
async def get_prediction_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Debug: print current user id for troubleshooting empty history
        try:
            print(f"[crop_disease.history] current_user.id={current_user.id}")
        except Exception:
            print("[crop_disease.history] current_user id not available")
        import json
        preds = db.query(CropPrediction).filter(CropPrediction.user_id == current_user.id).order_by(CropPrediction.created_at.desc()).limit(100).all()
        try:
            print(f"[crop_disease.history] query returned {len(preds)} predictions")
            # optionally print first few ids
            ids = [p.id for p in preds]
            print(f"[crop_disease.history] prediction ids: {ids}")
        except Exception:
            pass
        out = []
        for p in preds:
            probs = None
            try:
                prob_str = str(p.probabilities) if p.probabilities is not None else None
                if prob_str and isinstance(prob_str, str):
                    probs = json.loads(prob_str)
            except Exception:
                probs = None

            created_at_str = None
            try:
                if p.created_at is not None:
                    created_at_str = p.created_at.isoformat()
            except Exception:
                pass

            out.append({
                "id": p.id,
                "crop_type": p.crop_type,
                "predicted_class": p.predicted_class,
                "confidence": p.confidence,
                "probabilities": probs,
                "recommendation": p.recommendation,
                "prevention": p.prevention,
                "details": p.details,
                "created_at": created_at_str,
            })

        return {"predictions": out}
    except Exception as e:
        return {"error": str(e)}

@router.get("/crops")
async def get_available_crops():
    crops = list(crop_disease_service.models.keys())
    return {"crops": crops}
