from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth, profile, crop_disease, climate
from app import database
from app.models import user

app = FastAPI(title="AgroBrain Backend")

# DB tables
user.Base.metadata.create_all(bind=database.engine)

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

# Root
@app.get("/")
def root():
    return {"msg": "AgroBrain Backend Running 🚀"}
