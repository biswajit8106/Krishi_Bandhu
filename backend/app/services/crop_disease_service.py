from PIL import Image
import io
import base64
import os
import csv
import re
import json
from ultralytics import YOLO

class CropDiseaseService:
    def __init__(self):
        self.models = {}
        self.class_names = {}
        self.recommendations = {}
        self.analysis = {}
        self._load_models()
        self._load_recommendations()
        self._load_analysis()

    def _load_models(self):
        # Base path for YOLO models
        base_path = os.path.join(os.path.dirname(__file__), '..', 'ml_models', 'runs', 'classify')

        # Mapping of crop types to YOLO model directories
        crop_dirs = {
            'apple': 'Apple_YOLO_cls',
            'banana': 'Banana_YOLO_cls',
            'black_gram': 'Black_Gram_YOLO_cls',
            'brinjal': 'Brinjal_YOLO_cls',
            'cherry': 'Cherry_YOLO_cls',
            'chilli': 'Chilli_YOLO_cls',
            'corn': 'Corn_YOLO_cls',
            'grape': 'Grape_YOLO_cls',
            'pepper_bell': 'Pepper_bell_YOLO_cls',
            'potato': 'Potato_YOLO_cls',
            'rice': 'Rice_YOLO_cls',
            'soybean': 'Soybean_YOLO_cls',
            'strawberry': 'Strawberry_YOLO_cls',
            'sugarcane': 'Sugarcane_YOLO_cls',
            'tomato': 'Tomato_YOLO_cls',
            'wheat': 'Wheat_YOLO_cls'
        }

        for crop, dir_name in crop_dirs.items():
            model_path = os.path.join(base_path, dir_name, 'weights', 'best.pt')
            if os.path.exists(model_path):
                try:
                    # Load YOLO model
                    model = YOLO(model_path)
                    self.models[crop] = model
                    self.class_names[crop] = model.names
                    print(f"Loaded YOLO model for {crop} with {len(model.names)} classes: {list(model.names.values())}")
                except Exception as e:
                    print(f"Error loading YOLO model for {crop}: {e}")
            else:
                print(f"YOLO model file not found for {crop}: {model_path}")

    def preprocess_image(self, image_data):
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        # Save decoded image for debugging
        debug_image_path = os.path.join(os.path.dirname(__file__), '..', 'decoded_test_image.jpg')
        with open(debug_image_path, 'wb') as f:
            f.write(image_bytes)

        # Open image as PIL Image
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        return image

    def _load_recommendations(self):
        # Load disease -> recommendation/prevention mappings from CSV
        try:
            csv_path = os.path.join(os.path.dirname(__file__), '..', '..', 'Crop_Disease_Recommendations_Preventions.csv')
            csv_path = os.path.abspath(csv_path)
            if not os.path.exists(csv_path):
                print(f"Recommendations CSV not found at {csv_path}")
                return

            def normalize(s: str) -> str:
                s = s or ''
                s = s.strip().lower()
                # replace non-alphanumeric with underscore
                s = re.sub(r'[^a-z0-9]+', '_', s)
                # collapse multiple underscores
                s = re.sub(r'_+', '_', s).strip('_')
                return s

            with open(csv_path, newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    disease = (row.get('Disease') or row.get('disease') or '').strip()
                    recommendation = (row.get('Recommendation') or row.get('recommendation') or '').strip()
                    prevention = (row.get('Prevention') or row.get('prevention') or '').strip()
                    if not disease:
                        continue

                    # store several lookup keys including a normalized key
                    keys = set([
                        disease,
                        disease.lower(),
                        disease.replace(' ', '_'),
                        disease.replace(' ', '_').lower(),
                        normalize(disease),
                    ])
                    for k in keys:
                        self.recommendations[k] = {
                            'recommendation': recommendation,
                            'prevention': prevention
                        }
            print(f"Loaded {len(self.recommendations)} recommendation entries from CSV")
        except Exception as e:
            print(f"Failed to load recommendations CSV: {e}")

    def _load_analysis(self):
        """Load disease analysis metadata (severity, symptoms, optional recs) from JSON file."""
        try:
            json_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'disease_analysis.json')
            json_path = os.path.abspath(json_path)
            if not os.path.exists(json_path):
                print(f"Disease analysis JSON not found at {json_path}")
                return

            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            def normalize(s: str) -> str:
                s = s or ''
                s = s.strip().lower()
                s = re.sub(r'[^a-z0-9]+', '_', s)
                s = re.sub(r'_+', '_', s).strip('_')
                return s

            for key, val in data.items():
                if not key:
                    continue
                nkey = normalize(key)
                self.analysis[nkey] = val

                # also add some common alternative lookup keys from the disease field
                disease_name = (val.get('disease') or '')
                if disease_name:
                    self.analysis[normalize(disease_name)] = val

            print(f"Loaded {len(self.analysis)} analysis entries from JSON")
        except Exception as e:
            print(f"Failed to load disease analysis JSON: {e}")

    def predict(self, crop_type, image_data):
        if crop_type not in self.models:
            return {"error": f"YOLO model for crop '{crop_type}' not available"}

        model = self.models[crop_type]
        class_names = self.class_names[crop_type]

        try:
            # Preprocess image
            image = self.preprocess_image(image_data)

            # Make prediction using YOLO
            results = model.predict(image, verbose=False)

            # Extract top prediction
            if results and len(results) > 0:
                result = results[0]
                if result.probs is not None:
                    # Get top class and confidence
                    top_class_idx = result.probs.top1
                    top_confidence = result.probs.top1conf.item()
                    predicted_class = class_names[top_class_idx]

                    # Get all probabilities
                    probs = result.probs.data.tolist()
                    prob_dict = {class_names[i]: probs[i] for i in range(len(class_names))}

                    print(f"Prediction debug for crop '{crop_type}': {prob_dict}")

                    # Attach recommendation and prevention if available
                    rec = self._get_recommendation_for(predicted_class, crop_type)
                    analysis = self._get_analysis_for(predicted_class, crop_type)

                    response = {
                        "predicted_class": predicted_class,
                        "confidence": top_confidence,
                        "probabilities": prob_dict,
                    }

                    # merge recommendation/prevention from CSV-first, then analysis JSON if missing
                    if rec:
                        response.update(rec)

                    # analysis may contain severity and symptoms and optional recommendation/prevention
                    if analysis:
                        # do not overwrite recommendation/prevention if already present
                        for k, v in analysis.items():
                            if k in ('recommendation', 'prevention') and response.get(k):
                                continue
                            response[k] = v

                    return response
                else:
                    return {"error": "No probabilities found in prediction"}
            else:
                return {"error": "No prediction results"}

        except Exception as e:
            return {"error": f"Prediction failed: {str(e)}"}

    def _get_recommendation_for(self, disease_name: str, crop_type: str):
        if not disease_name:
            return None
        def normalize(s: str) -> str:
            s = s or ''
            s = s.strip().lower()
            s = re.sub(r'[^a-z0-9]+', '_', s)
            s = re.sub(r'_+', '_', s).strip('_')
            return s

        raw = disease_name
        norm = normalize(raw)
        crop_norm = normalize(crop_type)

        # Include crop-prefixed keys
        crop_prefixed_keys = [
            crop_type + '_' + raw,
            crop_type + '_' + raw.lower(),
            crop_type + '_' + raw.replace(' ', '_'),
            crop_type + '_' + raw.replace(' ', '_').lower(),
            crop_norm + '_' + norm,
        ]

        # Exact matches first, including crop-prefixed
        all_keys = list((raw, raw.lower(), raw.replace(' ', '_'), raw.replace(' ', '_').lower(), norm)) + crop_prefixed_keys
        for key in all_keys:
            if key in self.recommendations:
                return self.recommendations[key]

        # Fallback: substring or normalized substring match
        for k, v in self.recommendations.items():
            if not k:
                continue
            if norm and norm in normalize(k):
                return v
            if normalize(k) and normalize(k) in norm:
                return v

        # No recommendation found
        print(f"No recommendation mapping found for disease '{disease_name}' (normalized '{norm}') with crop '{crop_type}'")
        return None

    def _get_analysis_for(self, disease_name: str, crop_type: str):
        if not disease_name:
            return None

        def normalize(s: str) -> str:
            s = s or ''
            s = s.strip().lower()
            s = re.sub(r'[^a-z0-9]+', '_', s)
            s = re.sub(r'_+', '_', s).strip('_')
            return s

        raw = disease_name
        norm = normalize(raw)
        crop_norm = normalize(crop_type)

        # try exact and normalized lookups
        candidates = [raw, raw.lower(), raw.replace(' ', '_'), raw.replace(' ', '_').lower(), norm,
                      f"{crop_type}_{raw}", f"{crop_norm}_{norm}"]

        for key in candidates:
            k = normalize(key)
            if k in self.analysis:
                return self.analysis[k]

        # fallback: substring match
        for k, v in self.analysis.items():
            if not k:
                continue
            if norm and norm in k:
                return v
            if k in norm:
                return v

        return None

# Singleton instance
crop_disease_service = CropDiseaseService()