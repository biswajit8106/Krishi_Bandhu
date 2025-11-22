import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import base64
import os

class CropDiseaseService:
    def __init__(self):
        self.models = {}
        self.class_names = {}
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self._load_models()

    def _load_models(self):
        # Model paths and their corresponding class names
        base_path = os.path.join(os.path.dirname(__file__), '..', 'ml_models')
        model_configs = {
            'apple': {
                'path': os.path.join(base_path, 'Apple_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Apple Scab', 'Black Rot', 'Cedar Apple Rust']
            },
            'banana': {
                'path': os.path.join(base_path, 'banana_plant_disease_resnet18.pth'),
                'classes': ['Healthy', 'Banana Bunchy Top Virus', 'Banana Cordana', 'Banana Mosaic Virus']
            },
            'black_gram': {
                'path': os.path.join(base_path, 'black_gram_plant_disease_resnet18.pth'),
                'classes': ['Healthy', 'Anthracnose', 'Leaf Crinkle', 'Powdery Mildew', 'Yellow Mosaic']
            },
            'brinjal': {
                'path': os.path.join(base_path, 'brinjal_plant_disease_resnet18.pth'),
                'classes': ['Healthy', 'Bacterial Wilt', 'Fusarium Wilt']
            },
            'chilli': {
                'path': os.path.join(base_path, 'chilli_plant_disease_resnet18.pth'),
                'classes': ['Healthy', 'Leaf Curl', 'Leaf Spot', 'Whitefly', 'Yellowish']
            },
            'corn': {
                'path': os.path.join(base_path, 'Corn_(maize)_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Blight', 'Common Rust', 'Gray Leaf Spot']
            },
            'grape': {
                'path': os.path.join(base_path, 'Grape_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Black Measles', 'Black Rot', 'Leaf Blight']
            },
            'potato': {
                'path': os.path.join(base_path, 'Potato_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Early Blight', 'Late Blight']
            },
            'rice': {
                'path': os.path.join(base_path, 'Rice_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Bacterial Leaf Blight', 'Brown Spot', 'Leaf Smut', 'Tungro']
            },
            'soybean': {
                'path': os.path.join(base_path, 'Soybean_nb_resnet18_best.pth'),
                'classes': ['Healthy']
            },
            'sugarcane': {
                'path': os.path.join(base_path, 'Sugarcane_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Mosaic', 'Red Rot', 'Rust', 'Yellow']
            },
            'tomato': {
                'path': os.path.join(base_path, 'Tomato_nb_resnet18_best.pth'),
                'classes': ['Healthy', 'Bacterial Spot', 'Early Blight', 'Late Blight', 'Leaf Mold', 'Septoria Leaf Spot', 'Spider Mites', 'Target Spot', 'Tomato Yellow Leaf Curl Virus', 'Tomato Mosaic Virus']
            },
            'wheat': {
                'path': os.path.join(base_path, 'Wheat_plant_disease_resnet18.pth'),
                'classes': ['Healthy', 'Brown Rust', 'Septoria', 'Yellow Rust']
            }
        }

        for crop, config in model_configs.items():
            if os.path.exists(config['path']):
                try:
                    # Load ResNet18 model
                    model = models.resnet18(pretrained=False)
                    num_classes = len(config['classes'])

                    # Adjust the final layer based on model type
                    if crop in ['apple', 'corn', 'grape', 'potato', 'rice', 'soybean', 'sugarcane', 'tomato']:
                        model.fc = nn.Linear(model.fc.in_features, num_classes)
                    else:
                        # For models with custom fc layers (banana, black_gram, brinjal, chilli, wheat)
                        model.fc = nn.Sequential(
                            nn.Linear(512, 128),
                            nn.ReLU(),
                            nn.Dropout(0.5),
                            nn.Linear(128, num_classes)
                        )

                    # Load state dict
                    checkpoint = torch.load(config['path'], map_location=self.device)
                    if 'model_state_dict' in checkpoint:
                        state_dict = checkpoint['model_state_dict']
                    else:
                        state_dict = checkpoint

                    model.load_state_dict(state_dict)
                    model.to(self.device)
                    model.eval()

                    self.models[crop] = model
                    self.class_names[crop] = config['classes']
                    print(f"Loaded model for {crop} with {num_classes} classes")
                except Exception as e:
                    print(f"Error loading model for {crop}: {e}")
            else:
                print(f"Model file not found for {crop}: {config['path']}")

    def preprocess_image(self, image_data):
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        # Save decoded image for debugging
        debug_image_path = os.path.join(os.path.dirname(__file__), '..', 'decoded_test_image.jpg')
        with open(debug_image_path, 'wb') as f:
            f.write(image_bytes)

        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

        # Define transforms
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

        image_tensor = transform(image)
        return image_tensor.unsqueeze(0).to(self.device)

    def predict(self, crop_type, image_data):
        if crop_type not in self.models:
            return {"error": f"Model for crop '{crop_type}' not available"}

        model = self.models[crop_type]
        class_names = self.class_names[crop_type]

        try:
            # Preprocess image
            input_tensor = self.preprocess_image(image_data)

            # Make prediction
            with torch.no_grad():
                outputs = model(input_tensor)
                # Apply softmax to get probabilities
                probabilities = nn.functional.softmax(outputs, dim=1)
                confidence, predicted = torch.max(probabilities, 1)
                predicted_class = class_names[predicted.item()]
                confidence_score = confidence.item()

                # Debug: log all class probabilities for diagnosis
                prob_dict = {class_names[i]: float(probabilities[0,i]) for i in range(len(class_names))}
                print(f"Prediction debug for crop '{crop_type}': {prob_dict}")

            return {"prediction": predicted_class, "confidence": confidence_score, "probabilities": prob_dict}
        except Exception as e:
            return {"error": f"Prediction failed: {str(e)}"}

# Singleton instance
crop_disease_service = CropDiseaseService()
