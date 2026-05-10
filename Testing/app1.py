import streamlit as st
import requests
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

# -------------------------------
# CONFIG (CHANGE THIS)
# -------------------------------
CHANNEL_ID = "3303453"
READ_API_KEY = "0WTD5DZ5ZFKG9GMX"

# -------------------------------
# FETCH DATA FROM THINGSPEAK
# -------------------------------
def get_data(results=20):
    url = f"https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={READ_API_KEY}&results={results}"
    response = requests.get(url)
    data = response.json()

    df = pd.DataFrame(data['feeds'])

    # Convert to numeric safely
    df['field1'] = pd.to_numeric(df['field1'], errors='coerce')  # Soil
    df['field2'] = pd.to_numeric(df['field2'], errors='coerce')  # Temp
    df['field3'] = pd.to_numeric(df['field3'], errors='coerce')  # Humidity
    df['field4'] = pd.to_numeric(df['field4'], errors='coerce')  # Rain

    df['created_at'] = pd.to_datetime(df['created_at'])

    df = df.dropna()

    return df

# -------------------------------
# AI PREDICTION LOGIC
# -------------------------------
def predict_irrigation(soil, temp, humidity, rain):
    if rain == 1:
        return "❌ No Irrigation Needed", 0

    if soil < 30:
        return "💧 High Irrigation Needed", 10
    elif soil < 50:
        return "🌿 Moderate Irrigation", 5
    else:
        return "✅ No Irrigation Needed", 0

# -------------------------------
# PAGE SETUP
# -------------------------------
st.set_page_config(page_title="KrishiBandhu Dashboard", layout="wide")

st.title("🌾 KrishiBandhu Smart Irrigation Dashboard")

# -------------------------------
# AUTO REFRESH BUTTON
# -------------------------------
if st.button("🔄 Refresh Data"):
    st.rerun()

# -------------------------------
# GET DATA
# -------------------------------
df = get_data()

if df.empty:
    st.error("No data found! Check ThingSpeak connection.")
    st.stop()

latest = df.iloc[-1]

soil = float(latest['field1'])
temp = float(latest['field2'])
humidity = float(latest['field3'])
rain = int(latest['field4'])

decision, water = predict_irrigation(soil, temp, humidity, rain)

# -------------------------------
# METRICS (TOP CARDS)
# -------------------------------
col1, col2, col3, col4 = st.columns(4)

col1.metric("🌱 Soil Moisture", f"{soil:.2f}")
col2.metric("🌡 Temperature", f"{temp:.2f} °C")
col3.metric("💧 Humidity", f"{humidity:.2f} %")
col4.metric("🌧 Rain", "Yes" if rain == 1 else "No")

# -------------------------------
# ALERT SYSTEM
# -------------------------------
st.subheader("🚨 Soil Status")

if soil < 30:
    st.error("🚨 Soil is Dry! Irrigation Needed")
elif soil < 50:
    st.warning("⚠️ Moderate Moisture")
else:
    st.success("✅ Soil is Healthy")

# -------------------------------
# AI RESULT
# -------------------------------
st.subheader("🤖 AI Irrigation Prediction")

st.success(f"Decision: {decision}")
st.info(f"💧 Water Required: {water} Liters")

# -------------------------------
# SIMPLE CHARTS
# -------------------------------
st.subheader("📊 Easy Visualization")

# BAR CHART
bar_data = pd.DataFrame({
    "Sensor": ["Soil", "Temperature", "Humidity"],
    "Value": [soil, temp, humidity]
})

fig_bar = px.bar(bar_data, x="Sensor", y="Value", title="Current Sensor Values")
st.plotly_chart(fig_bar, use_container_width=True)

# GAUGE CHART (SOIL)
fig_gauge = go.Figure(go.Indicator(
    mode="gauge+number",
    value=soil,
    title={'text': "Soil Moisture Level"},
    gauge={
        'axis': {'range': [0, 100]},
        'bar': {'color': "green"},
        'steps': [
            {'range': [0, 30], 'color': "red"},
            {'range': [30, 60], 'color': "yellow"},
            {'range': [60, 100], 'color': "green"}
        ]
    }
))

st.plotly_chart(fig_gauge, use_container_width=True)

# PIE CHART (RAIN)
rain_label = "Rain Detected" if rain == 1 else "No Rain"

pie_data = pd.DataFrame({
    "Condition": [rain_label, "Other"],
    "Value": [1, 0.1]
})

fig_pie = px.pie(pie_data, names="Condition", values="Value", title="Rain Status")
st.plotly_chart(fig_pie, use_container_width=True)

# -------------------------------
# RAW DATA (OPTIONAL)
# -------------------------------
with st.expander("📄 Show Raw Data"):
    st.dataframe(df)