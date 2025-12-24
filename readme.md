# KrishiBandhu 🌾

*Empowering Farmers with AI-Driven Agricultural Solutions*

KrishiBandhu (Friend of Farmer) is a comprehensive mobile application designed to revolutionize farming practices through cutting-edge technology. This college project integrates artificial intelligence, machine learning, and modern mobile development to provide farmers with intelligent tools for crop disease detection, weather forecasting, irrigation management, and personalized agricultural assistance.

## 🚀 Features

### 🤖 AI-Powered Crop Disease Detection
- **Image Analysis**: Upload crop images for instant disease identification
- **Multi-Crop Support**: Supports 15+ crops including Wheat, Rice, Maize, Sugarcane, Potato, Tomato, and more
- **Treatment Recommendations**: Get detailed prevention and treatment advice
- **Confidence Scoring**: AI-powered accuracy assessment for reliable results

### 🌤️ Smart Weather Prediction
- **Real-time Weather**: Current temperature, humidity, wind speed, and conditions
- **7-Day Forecast**: Detailed weather predictions with precipitation chances
- **Farming Recommendations**: Weather-based agricultural advice and alerts
- **Location-based**: Personalized weather data for farm locations

### 🗣️ Intelligent Assistant
- **Multi-language Support**: English, Hindi, Kannada, Telugu, Tamil, and more
- **Voice & Text Input**: Natural language processing with speech recognition
- **Voice Output**: Text-to-speech responses in multiple languages
- **Agricultural Expertise**: Specialized knowledge in farming, irrigation, and crop management

### 💧 Irrigation Management
- **Smart Scheduling**: AI-recommended irrigation timing based on weather and crop needs
- **Soil Moisture Monitoring**: Real-time soil condition analysis
- **Water Conservation**: Optimized water usage recommendations

### 👤 User Management
- **Secure Authentication**: JWT-based login and registration
- **Profile Management**: Personalized user profiles with location tracking
- **Query History**: Track all assistant interactions and disease analyses

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **UI Components**: Material Design with custom themes
- **Key Packages**:
  - `http`: API communication
  - `image_picker`: Camera and gallery integration
  - `speech_to_text`: Voice input processing
  - `flutter_tts`: Text-to-speech output
  - `cached_network_image`: Efficient image loading
  - `shared_preferences`: Local data storage

### Backend (API Server)
- **Framework**: FastAPI (Python)
- **Database**: MySQL with SQLAlchemy ORM
- **Authentication**: JWT tokens with bcrypt password hashing
- **Machine Learning**: PyTorch, scikit-learn, Ultralytics YOLO
- **AI Integration**: Groq API for LLM-powered assistant
- **Additional Libraries**:
  - `pydantic`: Data validation
  - `python-multipart`: File upload handling
  - `gtts`: Text-to-speech generation
  - `speech_recognition`: Voice processing

### AI/ML Models
- **Disease Detection**: Custom-trained CNN models for crop disease classification
- **Weather Forecasting**: Integration with weather APIs and predictive models
- **Natural Language Processing**: Groq-powered conversational AI

## 📋 Prerequisites

- **Flutter**: SDK 3.9.0 or higher
- **Python**: 3.8 or higher
- **MySQL**: Database server
- **Git**: Version control

## 🚀 Installation & Setup

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd KrishiBandhu/backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**
   Create a `.env` file with:
   ```
   GROQ_API_KEY=your_groq_api_key
   DATABASE_URL=mysql://user:password@localhost/krishibandhu
   SECRET_KEY=your_secret_key
   ```

5. **Set up database**
   ```bash
   # Create MySQL database
   mysql -u root -p
   CREATE DATABASE krishibandhu;
   ```

6. **Run migrations**
   ```bash
   python -c "from app.database import Base, engine; Base.metadata.create_all(bind=engine)"
   ```

7. **Start the server**
   ```bash
   uvicorn app.main:app --reload
   ```

### Mobile App Setup

1. **Navigate to app directory**
   ```bash
   cd krishibandhu_app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update `lib/services/api_service.dart` with your backend URL:
   ```dart
   const String baseUrl = 'http://your-backend-url:8000';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📖 Usage

### For Farmers
1. **Register/Login**: Create an account with your farm location
2. **Disease Detection**: Select crop type, capture/upload image, get instant analysis
3. **Weather Check**: View current conditions and farming recommendations
4. **Ask Assistant**: Get farming advice via text or voice in your preferred language
5. **Irrigation Planning**: Receive smart irrigation scheduling based on weather

### API Endpoints

#### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration

#### Disease Detection
- `POST /disease/predict` - Analyze crop disease from image

#### Weather
- `GET /climate/predict` - Get weather forecast and recommendations

#### Assistant
- `POST /assistant/chat` - Text-based agricultural queries
- `POST /assistant/voice` - Voice-based queries with TTS response

#### Profile
- `GET /profile/me` - Get user profile
- `PUT /profile/update` - Update user information

## 🤝 Contributing

This is a college project developed by students. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request



## 🙏 Acknowledgments

- Agricultural experts for domain knowledge
- Open-source community for amazing tools and libraries
- Weather APIs and AI providers for data and intelligence

---

*Made with ❤️ for farmers worldwide*
