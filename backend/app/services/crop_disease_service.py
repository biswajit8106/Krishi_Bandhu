import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import os
from typing import Dict, List

class CropDiseaseService:
    def __init__(self):
        self.models: Dict[str, nn.Module] = {}
        self.class_to_idx: Dict[str, Dict[str, int]] = {}
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        # Define image preprocessing transform
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

        # Crop to model mapping
        self.crop_models = {
            "apple": "Apple_nb_resnet18_best.pth",
            "banana": "banana_plant_disease_resnet18.pth",
            "black_gram": "black_gram_plant_disease_resnet18.pth",
            "brinjal": "brinjal_plant_disease_resnet18.pth",
            "chilli": "chilli_plant_disease_resnet18.pth",
            "corn": "Corn_(maize)_nb_resnet18_best.pth",
            "grape": "Grape_nb_resnet18_best.pth",
            "potato": "Potato_nb_resnet18_best.pth",
            "rice": "Rice_nb_resnet18_best.pth",
            "soybean": "Soybean_nb_resnet18_best.pth",
            "sugarcane": "Sugarcane_nb_resnet18_best.pth",
            "tomato": "Tomato_nb_resnet18_best.pth",
            "wheat": "Wheat_plant_disease_resnet18.pth",
        }

    def load_model(self, crop: str) -> nn.Module:
        if crop not in self.crop_models:
            raise ValueError(f"Model for crop '{crop}' not found")

        if crop in self.models:
            return self.models[crop]

        model_path = os.path.join(os.path.dirname(__file__), "..", "ml_models", self.crop_models[crop])
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")

        # Load ResNet18 model
        model = models.resnet18(pretrained=False)
        num_ftrs = model.fc.in_features
        # Assuming 4 classes for all models, but this will be overridden by the model's output
        model.fc = nn.Linear(num_ftrs, 4)

        # Load trained weights
        checkpoint = torch.load(model_path, map_location=self.device)
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
        else:
            model.load_state_dict(checkpoint)

        # Store class to index mapping if available
        if 'class_to_idx' in checkpoint:
            self.class_to_idx[crop] = checkpoint['class_to_idx']

        model.to(self.device)
        model.eval()

        self.models[crop] = model
        return model

    def preprocess_image(self, image_bytes: bytes) -> torch.Tensor:
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        return self.transform(image).unsqueeze(0).to(self.device)

    def predict(self, crop: str, image_bytes: bytes) -> str:
        model = self.load_model(crop)
        input_tensor = self.preprocess_image(image_bytes)

        with torch.no_grad():
            outputs = model(input_tensor)
            _, predicted = torch.max(outputs, 1)
            predicted_idx = predicted.item()

            # Try to get the class name from class_to_idx mapping
            if crop in self.class_to_idx:
                idx_to_class = {v: k for k, v in self.class_to_idx[crop].items()}
                if predicted_idx in idx_to_class:
                    return idx_to_class[predicted_idx]

            # Fallback to class index if no mapping available
            return str(predicted_idx)

    def get_available_crops(self) -> List[str]:
        return list(self.crop_models.keys())
