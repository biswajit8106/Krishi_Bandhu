# backend/app/routes/crop_disease.py
from fastapi import APIRouter, UploadFile, File
import random

router = APIRouter()

diseases = ["Healthy", "Blight", "Rust", "Leaf Spot"]

@router.post("/predict")
async def predict_disease(file: UploadFile = File(...)):
    # ⚠️ Abhi dummy logic: random disease return karega
    result = random.choice(diseases)
    return {"filename": file.filename, "prediction": result}
