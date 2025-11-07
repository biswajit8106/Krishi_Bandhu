from fastapi import APIRouter, Form
from ..services.crop_disease_service import crop_disease_service

router = APIRouter()

@router.post("/predict")
async def predict_disease(crop_type: str = Form(...), file: str = Form(...)):
    try:
        # Make prediction using the service with base64 image data
        result = crop_disease_service.predict(crop_type.lower(), file)

        return {"crop_type": crop_type, **result}
    except Exception as e:
        return {"error": str(e)}

@router.get("/crops")
async def get_available_crops():
    crops = list(crop_disease_service.models.keys())
    return {"crops": crops}
