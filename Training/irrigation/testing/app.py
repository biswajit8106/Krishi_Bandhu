# ===================== Streamlit KrishiBandhu Test App ===================== #
import streamlit as st
import pandas as pd
import numpy as np
import torch
import joblib
from torch import nn
import matplotlib.pyplot as plt

# --------------------- Load Model & Scalers --------------------- #
class IrrigationModel(nn.Module):
    def __init__(self, input_dim):
        super(IrrigationModel, self).__init__()
        self.model = nn.Sequential(
            nn.Linear(input_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 64),
            nn.ReLU(),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, 1)
        )
    def forward(self, x):
        return self.model(x)

input_dim = 7  # Number of features: district_enc, soil_type_enc, crop_type_enc, day_after_sowing, temperature, rainfall, area
model = IrrigationModel(input_dim)
model.load_state_dict(torch.load("../irrigation_model.pt"))
model.eval()

scaler_X = joblib.load("../scaler_X.pkl")
scaler_y = joblib.load("../scaler_y.pkl")
le_district = joblib.load("../le_district.pkl")
le_soil = joblib.load("../le_soil.pkl")
le_crop = joblib.load("../le_crop.pkl")

# --------------------- Helper Functions --------------------- #
def encode_inputs(district, soil, crop):
    return le_district.transform([district])[0], le_soil.transform([soil])[0], le_crop.transform([crop])[0]

def predict_water(district, soil, crop, day, temp, rainfall, area):
    d_enc, s_enc, c_enc = encode_inputs(district, soil, crop)
    X_input = np.array([[d_enc, s_enc, c_enc, day, temp, rainfall, area]])
    X_scaled = scaler_X.transform(X_input)
    X_tensor = torch.tensor(X_scaled, dtype=torch.float32)
    with torch.no_grad():
        y_scaled = model(X_tensor).numpy()
        y = scaler_y.inverse_transform(y_scaled)
    return y[0][0]

def simulate_irrigation(district, soil, crop, area, temp_list, rainfall_list):
    water_req = []
    for i in range(len(temp_list)):
        water = predict_water(district, soil, crop, day=i+1,
                              temp=temp_list[i],
                              rainfall=rainfall_list[i],
                              area=area)
        water_req.append(water)
    return water_req

def plot_irrigation(water_list):
    st.line_chart(water_list)

# --------------------- Streamlit App --------------------- #
st.title("🌾 KrishiBandhu AI – Irrigation Predictor")

# Sidebar inputs
district = st.selectbox("Select District", le_district.classes_)
soil = st.selectbox("Select Soil Type", le_soil.classes_)
crop = st.selectbox("Select Crop", le_crop.classes_)
area = st.number_input("Area (Acres)", min_value=0.1, max_value=20.0, value=2.0, step=0.1)
days = st.slider("Number of Days to Simulate", min_value=1, max_value=60, value=30)

st.subheader("Weather Inputs (can be daily forecast or average)")

temperature = st.number_input("Temperature (°C)", min_value=0, max_value=50, value=28)
rainfall = st.number_input("Rainfall (mm/day)", min_value=0, max_value=100, value=5)

if st.button("Predict Irrigation"):
    temp_list = [temperature]*days
    rainfall_list = [rainfall]*days

    water_list = simulate_irrigation(district, soil, crop, area, temp_list, rainfall_list)

    st.subheader("💧 Predicted Daily Water Requirement (L/day)")
    plot_irrigation(water_list)

    total_water = sum(water_list)*0.85  # assuming 85% irrigation efficiency
    st.success(f"✅ Optimal Water Required: {total_water:.2f} Liters over {days} days")
