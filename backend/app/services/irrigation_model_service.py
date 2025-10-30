import torch
import torch.nn as nn
import pandas as pd
import numpy as np
import os
import logging

logger = logging.getLogger(__name__)


class IrrigationNN(nn.Module):
    def __init__(self, input_size):
        super(IrrigationNN, self).__init__()
        self.model = nn.Sequential(
            nn.Linear(input_size, 128),
            nn.ReLU(),
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, 1)
        )

    def forward(self, x):
        return self.model(x)


class IrrigationModelService:
    def __init__(self, model_path: str):
        """Load the PyTorch model and preprocessors."""
        model_dir = os.path.dirname(model_path)
        le_crop_file = os.path.join(model_dir, 'le_crop.pkl')
        le_district_file = os.path.join(model_dir, 'le_district.pkl')
        le_soil_file = os.path.join(model_dir, 'le_soil.pkl')
        scaler_X_file = os.path.join(model_dir, 'scaler_X.pkl')
        scaler_y_file = os.path.join(model_dir, 'scaler_y.pkl')

        try:
            # Load state_dict
            state_dict = torch.load(model_path, map_location=torch.device('cpu'))
            input_size = 7  # Based on the state_dict shape [128, 7]
            self.model = IrrigationNN(input_size)
            self.model.load_state_dict(state_dict)
            self.model.eval()
            logger.info("Loaded PyTorch model successfully.")
        except Exception as e:
            logger.exception("Failed to load PyTorch model: %s", e)
            self.model = None

        try:
            import joblib
            self.le_crop = joblib.load(le_crop_file)
            self.le_district = joblib.load(le_district_file)
            self.le_soil = joblib.load(le_soil_file)
            self.scaler_X = joblib.load(scaler_X_file)
            self.scaler_y = joblib.load(scaler_y_file)
            logger.info("Loaded preprocessors successfully.")
        except Exception as e:
            logger.exception("Failed to load preprocessors: %s", e)
            self.le_crop = self.le_district = self.le_soil = self.scaler_X = self.scaler_y = None

    def predict(self, input_data: dict):
        """Predict using the loaded PyTorch model if available; otherwise use a simple
        rule-based estimator based on crop, soil and recent precipitation.

        Returns a dictionary with 'liters_required', 'units', etc.
        """
        if self.model is not None and self.le_crop is not None and self.scaler_X is not None and self.scaler_y is not None:
            try:
                # Encode categorical variables
                district = input_data.get('district') or 'Unknown'
                crop_type = input_data.get('crop_type') or 'Unknown'
                soil_type = input_data.get('soil_type') or 'Unknown'
                area = float(input_data.get('area') or 1.0)

                # Encode using label encoders
                district_encoded = self.le_district.transform([district])[0] if hasattr(self.le_district, 'classes_') and district in self.le_district.classes_ else -1
                crop_encoded = self.le_crop.transform([crop_type])[0] if hasattr(self.le_crop, 'classes_') and crop_type in self.le_crop.classes_ else -1
                soil_encoded = self.le_soil.transform([soil_type])[0] if hasattr(self.le_soil, 'classes_') and soil_type in self.le_soil.classes_ else -1

                # Get weather data for temperature and rainfall
                weather = input_data.get('weather') or {}
                temperature = 28.0  # default
                rainfall = 5.0  # default
                try:
                    forecast = weather.get('forecast') if isinstance(weather, dict) else None
                    if forecast and isinstance(forecast, list) and len(forecast) > 0:
                        day_weather = forecast[0]
                        if 'temperature' in day_weather:
                            temperature = float(day_weather['temperature'])
                        if 'precipitation' in day_weather:
                            rainfall = float(day_weather['precipitation'])
                    else:
                        if 'temperature' in weather:
                            temperature = float(weather['temperature'])
                        if 'precipitation' in weather:
                            rainfall = float(weather['precipitation'])
                except Exception:
                    pass

                # Prepare input array - match 7 features: district_enc, soil_type_enc, crop_type_enc, day_after_sowing, temperature, rainfall, area
                day_after_sowing = 1  # assuming first day
                input_array = np.array([[district_encoded, soil_encoded, crop_encoded, day_after_sowing, temperature, rainfall, area]], dtype=np.float32)

                # Scale input
                input_scaled = self.scaler_X.transform(input_array)

                # Convert to tensor and predict
                input_tensor = torch.tensor(input_scaled, dtype=torch.float32)
                with torch.no_grad():
                    pred_scaled = self.model(input_tensor).item()

                # Inverse scale to get actual liters
                pred_actual = self.scaler_y.inverse_transform(np.array([[pred_scaled]])).ravel()[0]
                # Ensure non-negative prediction
                pred_actual = max(0, pred_actual)

                # Get weather for precip_percent
                weather = input_data.get('weather') or {}
                precip_percent = 0
                try:
                    forecast = weather.get('forecast') if isinstance(weather, dict) else None
                    if forecast and isinstance(forecast, list) and len(forecast) > 0:
                        p = forecast[0].get('precipitation')
                        if p is not None:
                            precip_percent = float(p)
                    else:
                        p = weather.get('precipitation') or weather.get('daily_precipitation')
                        if p is not None:
                            precip_percent = float(p)
                except Exception:
                    precip_percent = 0

                result = {
                    'liters_required': round(float(pred_actual), 1),
                    'units': 'liters',
                    'area': area,
                    'crop': crop_type,
                    'soil': soil_type,
                    'precip_percent': precip_percent,
                    'note': 'Predicted by trained PyTorch model.'
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
