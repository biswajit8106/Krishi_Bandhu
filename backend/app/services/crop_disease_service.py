from PIL import Image
import io
import base64
import os
from ultralytics import YOLO

class CropDiseaseService:
    def __init__(self):
        self.models = {}
        self.class_names = {}
        self._load_models()

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

                    return {"prediction": predicted_class, "confidence": top_confidence, "probabilities": prob_dict}
                else:
                    return {"error": "No probabilities found in prediction"}
            else:
                return {"error": "No prediction results"}

        except Exception as e:
            return {"error": f"Prediction failed: {str(e)}"}

# Singleton instance
crop_disease_service = CropDiseaseService()
