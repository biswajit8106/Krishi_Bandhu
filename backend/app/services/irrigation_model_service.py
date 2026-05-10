import torch
import torch.nn as nn
import pandas as pd
import numpy as np
import os
import logging

logger = logging.getLogger(__name__)


class IrrigationNN(nn.Module):
    def __init__(self, input_size, num_classes=3):
        super(IrrigationNN, self).__init__()
        self.model = nn.Sequential(
            nn.Linear(input_size, 128),
            nn.ReLU(),
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, num_classes)
        )

    def forward(self, x):
        return self.model(x)


class IrrigationModelService:
    def __init__(self, model_path: str):
        """Load the PyTorch model and preprocessors."""
        model_dir = os.path.dirname(model_path)
        le_crop_file = os.path.join(model_dir, 'le_crop.pkl')
        le_soil_file = os.path.join(model_dir, 'le_soil.pkl')
        le_season_file = os.path.join(model_dir, 'le_season.pkl')
        le_target_file = os.path.join(model_dir, 'le_target.pkl')
        scaler_X_file = os.path.join(model_dir, 'scaler_X.pkl')

        try:
            # Load state_dict
            state_dict = torch.load(model_path, map_location=torch.device('cpu'))
            input_size = 11  # Matches training: 3 encoded categoricals + 8 continuous features
            num_classes = 3  # Classification output: 3 irrigation need classes
            self.model = IrrigationNN(input_size, num_classes)
            self.model.load_state_dict(state_dict)
            self.model.eval()
            logger.info("Loaded PyTorch model successfully with input_size=%d, num_classes=%d", input_size, num_classes)
        except Exception as e:
            logger.exception("Failed to load PyTorch model: %s", e)
            self.model = None

        try:
            import joblib
            self.le_crop = joblib.load(le_crop_file)
            self.le_soil = joblib.load(le_soil_file)
            self.le_season = joblib.load(le_season_file) if os.path.exists(le_season_file) else None
            self.le_target = joblib.load(le_target_file) if os.path.exists(le_target_file) else None
            self.scaler_X = joblib.load(scaler_X_file)
            logger.info("Loaded preprocessors successfully.")
        except Exception as e:
            logger.exception("Failed to load preprocessors: %s", e)
            self.le_crop = self.le_soil = self.le_season = self.le_target = self.scaler_X = None

    def predict(self, input_data: dict):
        """Predict irrigation need using the loaded PyTorch model if available; 
        otherwise use a rule-based estimator.

        Returns a dictionary with 'irrigation_need' (classification: 'Low'/'Medium'/'High'), 
        'liters_required', 'units', etc.
        """
        # Check if all required preprocessors are available for ML model
        has_all_preprocessors = (
            self.model is not None 
            and self.le_crop is not None 
            and self.le_soil is not None
            and self.le_season is not None
            and self.le_target is not None
            and self.scaler_X is not None
        )
        
        if has_all_preprocessors:
            try:
                # Extract and encode categorical variables
                crop_type = input_data.get('crop_type') or 'Unknown'
                soil_type = input_data.get('soil_type') or 'Unknown'
                season = input_data.get('season') or 'Unknown'
                area = float(input_data.get('area') or 1.0)

                # Encode categorical features
                crop_encoded = self.le_crop.transform([crop_type])[0] if crop_type in self.le_crop.classes_ else 0
                soil_encoded = self.le_soil.transform([soil_type])[0] if soil_type in self.le_soil.classes_ else 0
                season_encoded = self.le_season.transform([season])[0] if season in self.le_season.classes_ else 0

                # Extract continuous features from input_data
                soil_moisture = float(input_data.get('soil_moisture', 60.0))
                temperature = float(input_data.get('temperature', 28.0))
                humidity = float(input_data.get('humidity', 70.0))
                rainfall = float(input_data.get('rainfall', 5.0))
                sunlight_hours = float(input_data.get('sunlight_hours', 8.0))
                wind_speed = float(input_data.get('wind_speed', 10.0))
                field_area = float(input_data.get('area', 1.0))
                previous_irrigation = float(input_data.get('previous_irrigation', 0.0))

                # Prepare input array with 11 features matching training data:
                # [Soil_Type_enc, Crop_Type_enc, Season_enc, Soil_Moisture, Temperature_C, 
                #  Humidity, Rainfall_mm, Sunlight_Hours, Wind_Speed_kmh, Field_Area_hectare, Previous_Irrigation_mm]
                input_array = np.array([[
                    soil_encoded, 
                    crop_encoded, 
                    season_encoded,
                    soil_moisture,
                    temperature,
                    humidity,
                    rainfall,
                    sunlight_hours,
                    wind_speed,
                    field_area,
                    previous_irrigation
                ]], dtype=np.float32)

                # Scale input
                input_scaled = self.scaler_X.transform(input_array)

                # Convert to tensor and predict
                input_tensor = torch.tensor(input_scaled, dtype=torch.float32)
                with torch.no_grad():
                    logits = self.model(input_tensor)
                    predicted_class = torch.argmax(logits, dim=1).item()

                # Decode predicted class back to irrigation need label
                irrigation_need = self.le_target.inverse_transform([predicted_class])[0]

                # Estimate liters based on classification
                liters_map = {
                    'Low': area * 1000,
                    'Medium': area * 2500,
                    'High': area * 4000
                }
                liters_required = liters_map.get(irrigation_need, area * 2500)

                result = {
                    'irrigation_need': irrigation_need,
                    'liters_required': round(float(liters_required), 1),
                    'units': 'liters',
                    'area': area,
                    'crop': crop_type,
                    'soil': soil_type,
                    'season': season,
                    'note': 'Predicted by trained PyTorch classification model.'
                }
                return result
            except Exception as e:
                logger.exception("PyTorch model prediction failed, falling back to rule-based: %s", e)

        # Fallback rule-based estimator
        crop = (input_data.get('crop_type') or '').lower()
        soil = (input_data.get('soil_type') or '').lower()
        area = float(input_data.get('area') or 1.0)
        weather = input_data.get('weather') or {}

        # base liters per acre per irrigation (very rough defaults)
        crop_base = {
            'rice': 6000,
            'wheat': 4000,
            'maize': 4500,
            'vegetables': 3000,
            'orchard': 3500,
        }
        base = crop_base.get(crop, 3500)

        soil_multiplier = {
            'sandy': 1.2,
            'clay': 0.9,
            'loam': 1.0,
            'silt': 1.0,
            'peaty': 1.1,
        }
        mult = soil_multiplier.get(soil, 1.0)

        # Estimate recent precipitation percent from weather data
        precip_percent = 0
        try:
            # look for forecast list
            forecast = weather.get('forecast') if isinstance(weather, dict) else None
            if forecast and isinstance(forecast, list) and len(forecast) > 0:
                p = forecast[0].get('precipitation')
                if p is not None:
                    precip_percent = float(p)
            else:
                # fallback to single-value keys
                p = weather.get('precipitation') or weather.get('daily_precipitation')
                if p is not None:
                    precip_percent = float(p)
        except Exception:
            precip_percent = 0

        # reduce need proportionally to precipitation percent (cap 0-100)
        precip_factor = max(0.0, min(precip_percent / 100.0, 1.0))

        # final liters = base * multiplier * area * (1 - precip_factor)
        liters_required = base * mult * area * (1.0 - precip_factor)

        result = {
            'liters_required': round(liters_required, 1),
            'units': 'liters',
            'area': area,
            'crop': crop,
            'soil': soil,
            'precip_percent': precip_percent,
            'note': 'Estimated by fallback rule-based predictor.'
        }

        return result
