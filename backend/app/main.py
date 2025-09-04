# backend/app/main.py
from fastapi import FastAPI
from app.routes import auth, profile, crop_disease,climate
from app import database
from app.models import user

app = FastAPI(title="AgroBrain Backend")

# DB tables बनाओ (development phase में, बाद में Alembic use करेंगे)
user.Base.metadata.create_all(bind=database.engine)

# Routers include करो
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(profile.router, prefix="/profile", tags=["Profile"])
app.include_router(crop_disease.router, prefix="/disease", tags=["Disease"])
app.include_router(climate.router, prefix="/climate", tags=["Climate"])

# Root test
@app.get("/")
def root():
    return {"msg": "AgroBrain Backend Running 🚀"}
