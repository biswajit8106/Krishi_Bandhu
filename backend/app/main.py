from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Use package-relative imports so running uvicorn from the backend folder works
from .routes import auth, profile, crop_disease, climate, irrigation
from . import database
app = FastAPI(title="AgroBrain Backend")
from .models import user
from .models import irrigation as irrigation_models

# DB tables: create all known models
database.Base.metadata.create_all(bind=database.engine)

# CORS
origins = ["*"]  # for dev, allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(profile.router, prefix="/profile", tags=["Profile"])
app.include_router(crop_disease.router, prefix="/disease", tags=["Disease"])
app.include_router(climate.router, prefix="/climate", tags=["Climate"])
app.include_router(irrigation.router)

# Root
@app.get("/")
def root():
    return {"msg": "AgroBrain Backend Running 🚀"}
