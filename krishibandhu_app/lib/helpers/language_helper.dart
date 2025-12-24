class LanguageHelper {
  // UI Name → Backend Language Code Mapping
  static const Map<String, String> uiToApiLang = {
    "English": "en",
    "हिन्दी": "hi",
    "मराठी": "mr",
    "తెలుగు": "te",
    "தமிழ்": "ta",
    "ಕನ್ನಡ": "kn",
    "ગુજરાતી": "gu",
    "বাংলা": "bn",
    "ਪੰਜਾਬੀ": "pa",
    "മലയാളം": "ml",
    "ଓଡିଆ": "or",
    "اردو": "ur",
  };

  /// Convert UI selection → API code
  static String toApiCode(String uiLang) {
    return uiToApiLang[uiLang] ?? "en"; // fallback to English
  }

  /// Validate codes coming from settings or API
  static String validateCode(String langCode) {
    if (uiToApiLang.containsValue(langCode)) return langCode;
    return "en"; // fallback
  }
}

