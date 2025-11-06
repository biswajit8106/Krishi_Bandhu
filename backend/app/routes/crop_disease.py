# backend/app/routes/crop_disease.py
from fastapi import APIRouter, UploadFile, File, Form
from ..services.crop_disease_service import CropDiseaseService
import base64

router = APIRouter()

disease_service = CropDiseaseService()

@router.post("/predict")
async def predict_disease(crop: str = Form(...), image: str = Form(...)):
    try:
        # Decode base64 image
        image_data = base64.b64decode(image)
        prediction = disease_service.predict(crop.lower(), image_data)
        return {"prediction": prediction}
    except Exception as e:
        return {"error": str(e)}

@router.get("/crops")
async def get_available_crops():
    return {"crops": disease_service.get_available_crops()}
