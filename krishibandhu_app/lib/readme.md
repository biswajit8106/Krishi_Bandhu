**Overview**: KrishiBandhu Flutter UI code (lib)
- **Purpose**: Frontend for KrishiBandhu — an AI-enabled smart farming app with features for crop disease detection, weather & climate prediction, irrigation scheduling, and a farmer assistant.

**Quick Start**:
- Prerequisites: `flutter` SDK installed, device/emulator available, backend server running (see API section).
- From PowerShell (project root `krishibandhu_app`):

```powershell
cd "c:\Projects\College Projects\Krishi_Bandhu\krishibandhu_app"
flutter pub get
flutter run
```

**Backend / API**:
- The app talks to the backend via `lib/services/api_service.dart`.
- Default base URL is set in `ApiService` as `http://localhost:9999`. If you run the backend on a different host/port or emulator, update `baseUrl` accordingly.
- Authentication tokens are stored in `SharedPreferences` under key `token` and accessed across screens.

**Project Structure (key files)**
- `lib/main.dart`: App entry; starts `AuthWrapper`.
- `lib/services/api_service.dart`: All REST calls (signup, login, disease prediction, climate prediction, irrigation endpoints, profile, schedules).
- `lib/theme/app_theme.dart`: Central theme, colors, light/dark ThemeData.

- Screens (high-level flows):
	- `lib/screens/login_screen.dart` — login and token storage.
	- `lib/screens/signup_screen.dart` — user registration.
	- `lib/screens/dashboard_screen.dart` — accessible dashboard with localization helper.
	- `lib/screens/profile_screen.dart` — user profile, settings, logout.
	- `lib/screens/crop_disease_screen.dart` — simple camera/gallery upload + prediction flow (two implementations exist: one in `screens/` and a richer UI in `krishi_screens/`).
	- `lib/screens/climate_screen.dart` and `lib/screens/weather_screen.dart` — climate & weather UI to show predictions.
	- `lib/screens/irrigation_fertilizer_screen.dart` & `lib/screens/irrigation_screen.dart` — irrigation & fertilizer UIs and prediction features.
	- `lib/screens/farmer_assistant_screen.dart` / `lib/krishi_screens/assistant_screen.dart` — chat-like virtual assistant UI.

- `lib/krishi_screens/` contains a more polished set of screens for the app (home, crop disease, weather, irrigation, assistant, profile) and assets for crop icons.

- Widgets (reusable UI components):
	- Cards & charts: `weather_card`, `weather_forecast_card`, `weather_chart`, `soil_moisture_chart`.
	- Action & stat widgets: `quick_action_button`, `quick_stats_card`, `profile_stat_card`, `feature_card`.
	- Irrigation: `irrigation_zone_card`, `irrigation_schedule_card`.
	- Disease UI: `disease_result_card`, `camera_button`.
	- Chat: `chat_message`, `assistant`-related small widgets.
	- Auth: `auth_wrapper.dart` chooses `HomeScreen` or `LoginScreen` based on stored token.

**Models** (`lib/models`) — data types used by UI:
- `user_models.dart` — user profile, preferences, farm info, farm stats.
- `weather_models.dart` — weather data, forecast, alerts.
- `irrigation_models.dart` — irrigation zones, schedules, water usage, predicted irrigation days.
- `disease_models.dart` — disease prediction results, crop disease info, scan history.

**Notable implementation details & tips**
- Two crop-disease screens exist: a simpler one under `lib/screens` (camera + upload) and a fuller UI in `lib/krishi_screens` (with assets and richer layout). The API used is `ApiService.predictDisease(token, cropType, base64Image)`.
- Weather and irrigation endpoints expect an authenticated token for some calls. If you see authentication errors, ensure `token` is present in `SharedPreferences` or adjust `ApiService` to bypass for local testing.
- Many UI widgets include placeholder or demo data and safe fallbacks when backend responses differ (e.g., `weatherCard` treats `msg`/`detail` shapes as errors).

**Assets**
- Crop images used by the richer screens are in `lib/krishi_screens/assets/` (e.g., `Apple.png`, `Banana.png`, `Wheat.png`, etc). Ensure `pubspec.yaml` includes these assets when building.

**Localization**
- `lib/screens/dashboard_screen.dart` contains an internal `AppLocalizations` helper with string maps for several languages (`en`, `hi` primarily) and a simple delegate used by the dashboard.

**How to develop & debug**
- Run the Flutter app while the backend is running. For Android emulator, you might need to use `10.0.2.2` or set `baseUrl` accordingly.
- To test disease prediction locally without a backend, you can mock `ApiService.predictDisease` to return a fixed `{'success': true, 'data': {'prediction': 'No disease', 'confidence': 0.95}}`.

**Contributing / Next steps**
- Update `lib/services/api_service.dart` when backend endpoints change.
- Complete empty widget files (`custom_textfield.dart`, `custom_button.dart`) or remove imports if unused.
- Add tests for service responses and widget smoke tests.

If you want, I can:
- run a quick search+lint to find any unused imports or empty files to remove;
- open or regenerate a README for the whole repo (root-level) that includes backend run instructions;
- or update `baseUrl` for a specific environment (emulator, device, or production).

---
Generated by an automated scan of `lib/` files to summarize UI structure and usage.

