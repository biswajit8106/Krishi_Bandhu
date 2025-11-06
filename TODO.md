c# TODO: Integrate Trained ML Models into Crop Disease Route and Add Crop Selection in Frontend

## Steps to Complete

- [x] Update backend/requirements.txt to include torch and torchvision for PyTorch model inference.
- [x] Create backend/app/services/crop_disease_service.py for model loading, image preprocessing, and prediction logic.
- [x] Update backend/app/routes/crop_disease.py to accept crop type, load the appropriate model, and perform prediction.
- [x] Update krishibandhu_app/lib/services/api_service.dart to send crop type with the image.
- [x] Update krishibandhu_app/lib/screens/crop_disease_screen.dart to include a crop selection dropdown before image upload.
- [ ] Install updated dependencies in backend.
- [ ] Test the prediction endpoint with different crops and images.
- [ ] Verify frontend integration by selecting crop, uploading image, and checking prediction.
