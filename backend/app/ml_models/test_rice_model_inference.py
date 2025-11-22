import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os

def load_rice_model(model_path, device):
    classes = ['Healthy', 'Bacterial Leaf Blight', 'Brown Spot', 'Leaf Smut', 'Tungro']
    model = models.resnet18(pretrained=False)
    num_classes = len(classes)
    model.fc = nn.Linear(model.fc.in_features, num_classes)
    checkpoint = torch.load(model_path, map_location=device)
    if 'model_state_dict' in checkpoint:
        state_dict = checkpoint['model_state_dict']
    else:
        state_dict = checkpoint
    model.load_state_dict(state_dict)
    model.to(device)
    model.eval()
    return model, classes

def preprocess_image(image_path, device):
    image = Image.open(image_path).convert('RGB')
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                             std=[0.229, 0.224, 0.225])
    ])
    image_tensor = transform(image)
    return image_tensor[None, ...].to(device)

def predict(model, classes, input_tensor):
    with torch.no_grad():
        outputs = model(input_tensor)
        probabilities = nn.functional.softmax(outputs, dim=1)
        confidence, predicted = torch.max(probabilities, 1)
        predicted_class = classes[predicted.item()]
        confidence_score = confidence.item()
        prob_dict = {classes[i]: float(probabilities[0, i]) for i in range(len(classes))}
    return predicted_class, confidence_score, prob_dict

def main():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model_path = os.path.join(os.path.dirname(__file__), 'Rice_nb_resnet18_best.pth')
    image_path = input("Enter path to rice diseased image: ")

    if not os.path.exists(model_path):
        print(f"Model file not found at {model_path}")
        return

    if not os.path.exists(image_path):
        print(f"Image file not found at {image_path}")
        return

    model, classes = load_rice_model(model_path, device)
    input_tensor = preprocess_image(image_path, device)
    predicted_class, confidence_score, prob_dict = predict(model, classes, input_tensor)

    print(f"Predicted Class: {predicted_class}")
    print(f"Confidence Score: {confidence_score:.4f}")
    print("Class probabilities:")
    for cls, prob in prob_dict.items():
        print(f"  {cls}: {prob:.4f}")

if __name__ == "__main__":
    main()
