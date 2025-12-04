# TODO: Integrate YOLOv8 Classification Models for Crop Disease Prediction

## Tasks to Complete

- [x] Update requirements.txt to add 'ultralytics' dependency
- [x] Modify crop_disease_service.py to import YOLO from ultralytics
- [x] Update _load_models method to load YOLO models from runs/classify directories with dynamic class names
- [x] Change preprocess_image method to return PIL Image instead of tensor
- [x] Update predict method to use model.predict API and extract top1 class, confidence, and probabilities
- [x] Install updated dependencies using pip install -r requirements.txt
- [x] Test the prediction endpoint to ensure YOLO models work correctly
