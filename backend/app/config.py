import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

# backend/app/config.py
DATABASE_URL = os.getenv("DATABASE_URL", "mysql+mysqlconnector://root@127.0.0.1:3306/agrobrain")
WEATHER_API_KEY = os.getenv("WEATHER_API_KEY", "270746a8e8a24a21bb190609250609")
SECRET_KEY = os.getenv("SECRET_KEY", "your_secret_key")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "YOUR_GROQ_API_KEY")  # Set your Groq API key here if available
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "YOUR_GEMINI_API_KEY")  # Set your Gemini API key here if available
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY")  # Set your OpenAI API key here if available
