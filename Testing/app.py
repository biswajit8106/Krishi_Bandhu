import streamlit as st
import requests
import pandas as pd
import plotly.graph_objects as go
import time

# ---------------- CONFIG ----------------
CHANNEL_ID = "3303453"
API_KEY = "0WTD5DZ5ZFKG9GMX"
URL = f"https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={API_KEY}&results=30"

st.set_page_config(page_title="KrishiBandhu Premium Dashboard", layout="wide")

# ---------------- CUSTOM CSS (DARK + GLASS UI) ----------------
st.markdown("""
<style>
body {
    background-color: #0E1117;
    color: white;
}
.metric-card {
    background: rgba(255,255,255,0.05);
    padding: 20px;
    border-radius: 15px;
    text-align: center;
    backdrop-filter: blur(10px);
}
</style>
""", unsafe_allow_html=True)

# ---------------- HEADER ----------------
st.title("KrishiBandhu AI Smart Farming")
st.caption("Real-Time IoT Dashboard")

# ---------------- SIDEBAR ----------------
st.sidebar.title("Control Panel")
refresh_rate = st.sidebar.slider("Refresh Rate (sec)", 5, 60, 10)

# ---------------- FETCH DATA ----------------
@st.cache_data(ttl=5)
def get_data():
    res = requests.get(URL)
    data = res.json()
    df = pd.DataFrame(data["feeds"])

    df["created_at"] = pd.to_datetime(df["created_at"])

    df = df.rename(columns={
        "field1": "Soil Moisture",
        "field2": "Temperature",
        "field3": "Humidity",
        "field4": "Rain",
        "field5": "Light"
    })

    for col in ["Soil Moisture", "Temperature", "Humidity", "Rain", "Light"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    return df

df = get_data()
latest = df.iloc[-1]

# ---------------- GAUGE FUNCTION ----------------
def gauge(title, value, min_val, max_val):
    fig = go.Figure(go.Indicator(
        mode="gauge+number",
        value=value,
        title={'text': title},
        gauge={
            'axis': {'range': [min_val, max_val]},
            'bar': {'color': "lightgreen"},
        }
    ))
    fig.update_layout(height=250)
    return fig

# ---------------- KPI GAUGES ----------------
st.subheader("📊 Live Sensor Gauges")

c1, c2, c3, c4, c5 = st.columns(5)

c1.plotly_chart(gauge("Soil Moisture (%)", latest["Soil Moisture"], 0, 100), use_container_width=True)
c2.plotly_chart(gauge("Temperature (°C)", latest["Temperature"], 0, 50), use_container_width=True)
c3.plotly_chart(gauge("Humidity (%)", latest["Humidity"], 0, 100), use_container_width=True)
c4.plotly_chart(gauge("Rain", latest["Rain"], 0, 10), use_container_width=True)
c5.plotly_chart(gauge("Light (lx)", latest["Light"], 0, 1000), use_container_width=True)

# ---------------- AI RECOMMENDATION ENGINE ----------------
st.subheader("AI Farming Insights")

def ai_insights():
    insights = []

    if latest['Soil Moisture'] < 30:
        insights.append(" Start irrigation immediately (soil too dry)")
    elif latest['Soil Moisture'] > 80:
        insights.append("Stop irrigation (waterlogging risk)")

    if latest['Temperature'] > 35:
        insights.append(" High temperature → Use shading / irrigation cooling")

    if latest['Humidity'] < 40:
        insights.append("🌫 Low humidity → consider mist irrigation")

    if latest['Rain'] < 2000:
        insights.append("🌧 Rain detected → Pause irrigation system")

    if latest['Light'] < 200:
        insights.append(" Low sunlight → Crop growth may slow")

    return insights

insights = ai_insights()

if insights:
    for i in insights:
        st.warning(i)
else:
    st.success(" Farm conditions are optimal")

# ---------------- WEATHER WIDGET ----------------
st.subheader("🌦 Weather Forecast (Smart Decision Support)")
st.info(" Tip: Combine weather + soil data for smarter irrigation decisions")

# ---------------- CHARTS ----------------
st.subheader(" Advanced Trends")

col1, col2 = st.columns(2)

with col1:
    st.line_chart(df.set_index("created_at")[["Temperature", "Humidity"]])

with col2:
    st.line_chart(df.set_index("created_at")[["Soil Moisture", "Light"]])

# ---------------- RAIN CHART ----------------
st.subheader("🌧 Rain Activity")
st.bar_chart(df.set_index("created_at")[["Rain"]])

# ---------------- DATA TABLE ----------------
with st.expander(" Raw Sensor Data"):
    st.dataframe(df.tail(10))

# ---------------- AUTO REFRESH ----------------
time.sleep(refresh_rate)
st.rerun()