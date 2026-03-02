from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Use package-relative imports so running uvicorn from the backend folder works
from .routes import auth, profile, crop_disease, climate, irrigation, assistant
from . import database
app = FastAPI(title="AgroBrain Backend")
from . import models  # Import all models to configure mappers

# DB tables: create all known models with retry logic
database.create_tables_with_retry(max_retries=3, initial_wait=2)

try:
    # ensure any new columns for users exist (helpful during deployments without alembic)
    database.ensure_user_verification_columns()
except Exception:
    # don't crash startup for migration helper failures; log to stdout
    import traceback
    traceback.print_exc()

# CORS
origins = ["*"]  # for dev, allow all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Routers
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(profile.router, prefix="/profile", tags=["Profile"])
app.include_router(crop_disease.router, prefix="/disease", tags=["Disease"])
app.include_router(climate.router, prefix="/climate", tags=["Climate"])
app.include_router(irrigation.router)
app.include_router(assistant.router)

# Root
@app.get("/")
def root():
    return {"msg": "AgroBrain Backend Running 🚀"}
