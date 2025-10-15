
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../services/api_service.dart';
import 'crop_disease_screen.dart';
import 'climate_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Locale _locale = Locale('en');
  int _currentIndex = 0;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: _DashboardHome(
        token: widget.token,
        onLocaleChange: setLocale,
        currentIndex: _currentIndex,
        onTabChange: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final String token;
  final void Function(Locale) onLocaleChange;
  final int currentIndex;
  final void Function(int) onTabChange;
  const _DashboardHome({required this.token, required this.onLocaleChange, required this.currentIndex, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget body;
    if (currentIndex == 3) {
      body = ProfileScreen(token: token);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          double width = constraints.maxWidth;
          if (width > 1000) crossAxisCount = 4;
          else if (width > 700) crossAxisCount = 3;
          if (width < 400) crossAxisCount = 1;
          double cardAspect = width < 400 ? 1.2 : 0.95;
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: width < 400 ? 4 : 16,
                vertical: width < 400 ? 4 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: width < 400 ? 6 : 12,
                    mainAxisSpacing: width < 400 ? 6 : 12,
                    childAspectRatio: cardAspect,
                    children: [
                      _buildDashboardCard(context, Icons.camera_alt, loc.t('crop_detection_title'), loc.t('crop_detection_action'), loc.t('crop_detection_sub'), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CropDiseaseScreen(token: token)));
                      }),
                      _buildDashboardCard(context, Icons.cloud, loc.t('climate_title'), loc.t('climate_action'), loc.t('climate_sub'), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClimateScreen()));
                      }),
                      _buildDashboardCard(context, Icons.water_drop, loc.t('irrigation_title'), loc.t('irrigation_action'), loc.t('irrigation_sub'), () {
                        // TODO: Implement irrigation screen navigation
                      }),
                      _buildDashboardCard(context, Icons.smart_toy, loc.t('assistant_title'), loc.t('assistant_action'), loc.t('assistant_sub'), () {
                        // TODO: Implement assistant screen navigation
                      }),
                    ],
                  ),
                  SizedBox(height: width < 400 ? 10 : 20),
                  // ...existing code...
                ],
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.green[700],
        title: Row(
          children: [
            Icon(Icons.agriculture, size: 28, color: Colors.white),
            SizedBox(width: 8),
            Text(loc.t('app_name')),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications)),
          PopupMenuButton<Locale>(
            onSelected: (locale) => onLocaleChange(locale),
            itemBuilder: (ctx) => AppLocalizations.supportedLocales
                .map((l) => PopupMenuItem<Locale>(
                      value: l,
                      child: Text(AppLocalizations.languageName(l.languageCode)),
                    ))
                .toList(),
            icon: Icon(Icons.language),
            tooltip: loc.t('change_language'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.t('welcome'),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        onTap: onTabChange,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: AppLocalizations.of(context).t('home')),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: AppLocalizations.of(context).t('assistant')),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: AppLocalizations.of(context).t('community')),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: AppLocalizations.of(context).t('profile')),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, IconData icon, String title, String buttonText, String subtitle, VoidCallback onPressed) {
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.3);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Colors.green[700]),
                SizedBox(height: 10),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale)),
                SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 12 * textScale, color: Colors.grey[600])),
                SizedBox(height: 8),
                // Use Flexible to avoid overflow, and let button always be visible
                const Spacer(flex: 1),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onPressed,
                    child: Text(buttonText, style: TextStyle(fontSize: 13 * textScale)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.green[100],
          radius: 28,
          child: Icon(icon, color: Colors.green[700], size: 28),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13)),
      ],
    );
  }
}

// -----------------------------
// Simple in-file localization helper
// -----------------------------

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
    Locale('te'), // Telugu
    Locale('bn'), // Bengali
    Locale('ta'), // Tamil
    Locale('kn'), // Kannada
    Locale('gu'), // Gujarati
    Locale('pa'), // Punjabi
    Locale('or'), // Odia
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static String languageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'mr':
        return 'मराठी';
      case 'te':
        return 'తెలుగు';
      case 'bn':
        return 'বাংলা';
      case 'ta':
        return 'தமிழ்';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'gu':
        return 'ગુજરાતી';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'or':
        return 'ଓଡ଼ିଆ';
      default:
        return code;
    }
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'KrishiBandhu',
      'welcome': "Hello Farmer! Let's grow smarter today.",
      'change_language': 'Change language',
      'crop_detection_title': 'Crop Disease Detection',
      'crop_detection_action': 'Scan Crop',
      'crop_detection_sub': 'Detect diseases instantly using AI.',
      'climate_title': 'AI Climate Predictor',
      'climate_action': 'Check Weather & Soil Report',
      'climate_sub': 'Plan farming with accurate predictions.',
      'irrigation_title': 'Smart Irrigation & Fertilizer',
      'irrigation_action': 'Irrigation Status',
      'irrigation_sub': 'Get real-time soil & nutrient insights.',
      'assistant_title': 'Farmer Virtual Assistant',
      'assistant_action': 'Ask KrishiBandhu',
      'assistant_sub': 'Get help in your own language.',
      'quick_access': 'Quick Access',
      'market_prices': 'Market Prices',
      'govt_schemes': 'Govt. Schemes',
      'farming_tips': 'Farming Tips',
      'satellite_insights': 'Satellite Insights',
      'home': 'Home',
      'assistant': 'Assistant',
      'community': 'Community',
      'profile': 'Profile',
    },
    'hi': {
      'app_name': 'कृषिबन्धु',
      'welcome': 'नमस्ते किसान! आइए आज और स्मार्ट तरीके से खेती करें।',
      'change_language': 'भाषा बदलें',
      'crop_detection_title': 'फसल रोग पहचान',
      'crop_detection_action': 'फसल स्कैन करें',
      'crop_detection_sub': 'AI की मदद से तुरंत रोग पहचानें।',
      'climate_title': 'AI मौसम पूर्वानुमान',
      'climate_action': 'मौसम और मृदा रिपोर्ट देखें',
      'climate_sub': 'सटीक पूर्वानुमान के साथ योजना बनाएं।',
      'irrigation_title': 'स्मार्ट सिंचाई और उर्वरक',
      'irrigation_action': 'सिंचाई स्थिति',
      'irrigation_sub': 'मृदा और पोषक तत्वों की वास्तविक समय जानकारी।',
      'assistant_title': 'किसान वर्चुअल सहायक',
      'assistant_action': 'कृषिबन्धु से पूछें',
      'assistant_sub': 'अपनी भाषा में मदद पाएं।',
      'quick_access': 'त्वरित पहुँच',
      'market_prices': 'बाज़ार भाव',
      'govt_schemes': 'सरकारी योजनाएँ',
      'farming_tips': 'खेती सुझाव',
      'satellite_insights': 'सैटेलाइट इनसाइट्स',
      'home': 'मुखपृष्ठ',
      'assistant': 'सहायक',
      'community': 'समुदाय',
      'profile': 'प्रोफ़ाइल',
    },
    'mr': {},
    'te': {},
    'bn': {},
    'ta': {},
    'kn': {},
    'gu': {},
    'pa': {},
    'or': {},
  };

  String t(String key) {
    final map = _localizedValues[locale.languageCode] ?? {};
    return map[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.map((l) => l.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
