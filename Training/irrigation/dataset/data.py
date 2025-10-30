import pandas as pd
import numpy as np

# -------------------- Jharkhand Districts -------------------- #
districts = [
    "Ranchi","Jamshedpur","Chaibasa","Dhanbad","Bokaro","Hazaribagh",
    "Giridih","Deoghar","Godda","Dumka","Palamu","Garhwa","Ramgarh",
    "Latehar","Pakur","Saraikela-Kharsawan","Khunti","Simdega",
    "Lohardaga","Chatra","Koderma","Sahebganj"
]

# -------------------- Crops -------------------- #
crops = [
    "Rice","Wheat","Maize","Sugarcane","Millet","Barley","Ragi","Arhar",
    "Urad","Moong","Gram","Mustard","Groundnut","Soybean","Potato","Tomato",
    "Onion","Cauliflower","Cabbage","Brinjal","Chilli","Ladyfinger","Sunflower",
    "Mango","Litchi","Guava","Papaya","Jackfruit","Cashew nut","Tea"
]

# -------------------- Soil Types -------------------- #
soils = ["Red Soil","Alluvial Soil","Black Soil","Laterite Soil","Clay Loam","Gravelly Loam","Mixed Loam Soil"]

# -------------------- Generate Synthetic Dataset -------------------- #
n = 50000  # 50k rows
data = []

for _ in range(n):
    district = np.random.choice(districts)
    crop = np.random.choice(crops)
    soil = np.random.choice(soils)
    day = np.random.randint(1, 151)  # Day after sowing
    temp = round(np.random.uniform(20, 36),1)
    rainfall = round(np.random.uniform(0,20),1)
    area = round(np.random.choice([0.5,1,2,2.5,3,4,5]),2)
    
    # Water requirement in mm/day influenced by day after sowing
    # Early days: lower water, middle days: medium, late: higher
    if day < 50:
        day_factor = 0.8
    elif day < 100:
        day_factor = 1.0
    else:
        day_factor = 1.2
    
    base_mm = (5 + (temp*0.1) - (rainfall*0.05)) * day_factor
    
    # Crop factor adjustments
    crop_factors = {
        "Rice":1.2,"Maize":1.1,"Wheat":0.9,"Sugarcane":1.3,"Millet":0.8,"Ragi":0.8,
        "Barley":0.85,"Arhar":0.85,"Urad":0.85,"Moong":0.85,"Gram":0.85,
        "Mustard":1.0,"Groundnut":1.0,"Soybean":1.0,
        "Potato":1.1,"Tomato":1.1,"Onion":1.1,"Cauliflower":1.1,"Cabbage":1.1,
        "Brinjal":1.1,"Chilli":1.1,"Ladyfinger":1.1,
        "Sunflower":1.2,"Mango":1.2,"Litchi":1.2,"Guava":1.2,"Papaya":1.2,
        "Jackfruit":1.2,"Cashew nut":1.2,"Tea":1.2
    }
    
    water_mm_per_day = round(base_mm * crop_factors[crop],2)
    
    # Convert to liters/day: 1 mm over 1 hectare = 10,000 liters
    # 1 acre = 0.404686 hectares → factor = 4046.86 liters per mm per acre
    water_liters = round(water_mm_per_day * area * 4046.86, 1)
    
    data.append([district, crop, soil, day, temp, rainfall, water_mm_per_day, area, water_liters])

# -------------------- Create DataFrame -------------------- #
df = pd.DataFrame(data, columns=[
    "District","Crop","Soil_Type","Day_After_Sowing",
    "Temperature_C","Rainfall_mm","Water_Requirement_mm_per_day",
    "Area_in_Acre","Water_Requirement_Liters_per_day"
])

# -------------------- Save CSV -------------------- #
df.to_csv("jharkhand_irrigation_50000.csv", index=False)
print("✅ Synthetic dataset with 50,000+ rows (without stage) created!")
