# create_tables.py
from app.database import Base, engine
from app.models.crop_prediction import CropPrediction
Base.metadata.create_all(bind=engine)
print('tables created')