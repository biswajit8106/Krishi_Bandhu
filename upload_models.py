"""
Script to upload YOLO models to Hugging Face
Repository: cosmic1112/Yolo_models
"""

import os
from huggingface_hub import HfApi, create_repo

# Configuration
REPO_ID = "cosmic1112/Yolo_models"
MODEL_DIR = "x:/KrishiBandhu/backend/app/ml_models/runs/classify"

# List of YOLO model folders
YOLO_MODELS = [
    "Apple_YOLO_cls",
    "Banana_YOLO_cls", 
    "Black_Gram_YOLO_cls",
    "Brinjal_YOLO_cls",
    "Cherry_YOLO_cls",
    "Chilli_YOLO_cls",
    "Corn_YOLO_cls",
    "Grape_YOLO_cls",
    "Pepper_bell_YOLO_cls",
    "Potato_YOLO_cls",
    "Rice_YOLO_cls",
    "Soybean_YOLO_cls",
    "Strawberry_YOLO_cls",
    "Sugarcane_YOLO_cls",
    "Tomato_YOLO_cls",
    "Wheat_YOLO_cls"
]

def upload_yolo_models():
    # Initialize the HF API
    api = HfApi()
    
    # Create the repository if it doesn't exist
    try:
        create_repo(REPO_ID, repo_type="model", exist_ok=True)
        print(f"Repository '{REPO_ID}' created or already exists.")
    except Exception as e:
        print(f"Error creating repo: {e}")
        return
    
    # Upload each model's best.pt file
    for model_name in YOLO_MODELS:
        model_path = os.path.join(MODEL_DIR, model_name, "weights", "best.pt")
        
        if os.path.exists(model_path):
            try:
                # Upload the file with folder name as the model name
                model_file_path = f"{model_name}/best.pt"
                api.upload_file(
                    path_or_fileobj=model_path,
                    path_in_repo=model_file_path,
                    repo_id=REPO_ID,
                    repo_type="model"
                )
                print(f"✓ Uploaded: {model_name}/best.pt")
            except Exception as e:
                print(f"✗ Error uploading {model_name}: {e}")
        else:
            print(f"⚠ Model not found: {model_path}")
    
    print(f"\nAll models uploaded successfully to https://huggingface.co/{REPO_ID}")

if __name__ == "__main__":
    # Check if user is logged in
    token = os.environ.get("HF_TOKEN")
    if not token:
        print("Warning: HF_TOKEN environment variable not set.")
        print("Please run: huggingface-cli login")
        print("Or set the HF_TOKEN environment variable.")
    
    upload_yolo_models()
