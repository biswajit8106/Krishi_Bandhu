import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_info_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/iot_dashboard_widget.dart';
import '../services/api_service.dart';

class IrrigationScreen extends StatefulWidget {
  final String token;
  const IrrigationScreen({super.key, required this.token});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen>
    with TickerProviderStateMixin {
  // dynamic metadata from backend
  List<String> _cropTypes = [];
  List<String> _soilTypes = [];
  List<dynamic> _waterUsage = [];
  List<dynamic> _recentEvents = [];

  // TabController
  late TabController _tabController;

  // Form controllers
  final ApiService api = ApiService();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController(
    text: '28',
  );
  final TextEditingController _rainfallController = TextEditingController(
    text: '5',
  );
  final TextEditingController _dayAfterSowingController = TextEditingController(
    text: '1',
  );
  final TextEditingController _previousIrrigationController = TextEditingController(
    text: '0',
  );
  final TextEditingController _sunlightController = TextEditingController(
    text: '8',
  );
  final TextEditingController _windSpeedController = TextEditingController(
    text: '5',
  );
  final TextEditingController _humidityController = TextEditingController(
    text: '60',
  );
  String? _selectedCropType;
  String? _selectedSoilType;
  String? _selectedSeason;

  bool _isLoading = false;
  String? _predictionText;
  List<dynamic> _dayWiseRequirements = [];
  Map<String, dynamic>? _weatherData;

  // SharedPreferences keys
  static const String _predictionTextKey = 'prediction_text';
  static const String _dayWiseRequirementsKey = 'day_wise_requirements';
  static const String _selectedCropTypeKey = 'selected_crop_type';
  static const String _selectedSoilTypeKey = 'selected_soil_type';
  static const String _areaKey = 'area';
  static const String _temperatureKey = 'temperature';
  static const String _rainfallKey = 'rainfall';
  static const String _dayAfterSowingKey = 'day_after_sowing';
  static const String _districtKey = 'district';
  static const String _villageKey = 'village';
  static const String _seasonKey = 'season';
  static const String _previousIrrigationKey = 'previous_irrigation_mm';

  Future<void> _loadIrrigationMetadata() async {
    final meta = await api.getIrrigationMetadata();
    if (meta.containsKey('crops') || meta.containsKey('soils')) {
      setState(() {
        _cropTypes = List<String>.from(meta['crops'] ?? []);
        _soilTypes = List<String>.from(meta['soils'] ?? []);
      });
    }
  }

  Future<void> _loadWaterUsage() async {
    try {
      final res = await api.getWaterUsage(widget.token, days: 30);
      if (res['success'] == true) {
        setState(() {
          _waterUsage = res['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecentActivity() async {
    try {
      final res = await api.getRecentIrrigationEvents(widget.token);
      if (res['success'] == true) {
        setState(() {
          _recentEvents = res['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _areaController.dispose();
    _temperatureController.dispose();
    _rainfallController.dispose();
    _dayAfterSowingController.dispose();
    _previousIrrigationController.dispose();
    _sunlightController.dispose();
    _windSpeedController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await api.getProfile(widget.token);
      if (profile.containsKey('email')) {
        setState(() {
          _districtController.text = profile['district'] ?? '';
          _villageController.text =
              profile['location'] ?? profile['village'] ?? '';
        });
        // Fetch weather after profile is loaded
        await _fetchWeather();
      }
    } catch (_) {}
  }

  Future<void> _fetchWeather() async {
    try {
      final city = _villageController.text.trim().isNotEmpty
          ? _villageController.text
          : _districtController.text.trim();
      if (city.isEmpty) return;

      final data = await api.predictClimate(widget.token);
      if (data.containsKey('temperature') || data.containsKey('forecast')) {
        setState(() {
          _weatherData = data;
          // Auto-populate temperature and rainfall from weather data
          final temp = data['temperature'];
          final forecast = data['forecast'];
          if (temp != null && temp is num) {
            _temperatureController.text = temp.toStringAsFixed(1);
          }
          // Use today's precipitation from forecast
          if (forecast != null && forecast is List && forecast.isNotEmpty) {
            final today = forecast[0];
            final precip = today['precipitation'];
            if (precip != null && precip is num) {
              _rainfallController.text = precip.toString();
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchIoTAndWeatherData() async {
    try {
      // Fetch IoT real-time sensor data
      final iotData = await api.getIotRealtimeData(widget.token);
      if (iotData.containsKey('data')) {
        final data = iotData['data'];
        setState(() {
          if (data['temperature'] != null) {
            _temperatureController.text = data['temperature'].toStringAsFixed(1);
          }
          if (data['humidity'] != null) {
            _humidityController.text = data['humidity'].toStringAsFixed(1);
          }
        });
      }
    } catch (_) {}

    // Fetch weather data
    await _fetchWeather();

    try {
      // Also fetch sunlight and wind speed from weather API
      final weatherData = await api.predictClimate(widget.token);
      if (weatherData.containsKey('forecast')) {
        final forecast = weatherData['forecast'];
        if (forecast is List && forecast.isNotEmpty) {
          final today = forecast[0];
          if (today['sunlight_hours'] != null) {
            _sunlightController.text = today['sunlight_hours'].toStringAsFixed(1);
          }
          if (today['wind_speed'] != null) {
            _windSpeedController.text = today['wind_speed'].toStringAsFixed(1);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Irrigation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'IoT Dashboard'),
            Tab(text: 'Smart Prediction'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IotDashboardWidget(token: widget.token),
          _buildDashboard(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, token: widget.token),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictionCard(),
          const SizedBox(height: 24),
          if (_predictionText != null && _dayWiseRequirements.isNotEmpty) ...[
            _buildPredictionDetailsSection(),
            const SizedBox(height: 24),
          ],
          if (_weatherData != null) ...[
            WeatherInfoCard(weatherData: _weatherData!),
            const SizedBox(height: 16),
          ],
          _buildWaterUsageStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Irrigation Prediction',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _districtController,
              decoration: const InputDecoration(labelText: 'District'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _villageController,
              decoration: const InputDecoration(labelText: 'Village/City'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _cropTypes.contains(_selectedCropType)
                  ? _selectedCropType
                  : null,
              items:
                  (_cropTypes.isNotEmpty
                          ? _cropTypes
                          : ['Barley', 'Urad', 'Jackfruit', 'Ragi', 'Millet', 'Tea', 'Gram', 'Brinjal', 'Soybean', 'Mango', 'Ladyfinger', 'Moong', 'Papaya', 'Maize', 'Litchi', 'Sugarcane', 'Groundnut', 'Cabbage', 'Sunflower', 'Rice', 'Potato', 'Mustard', 'Arhar', 'Onion', 'Cashew nut', 'Cauliflower', 'Wheat', 'Chilli', 'Tomato', 'Guava'])
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) {
                setState(() => _selectedCropType = v);
                _saveData();
              },
              decoration: const InputDecoration(labelText: 'Crop Type'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _soilTypes.contains(_selectedSoilType)
                  ? _selectedSoilType
                  : null,
              items:
                  (_soilTypes.isNotEmpty
                          ? _soilTypes
                          : ['Red Soil', 'Gravelly Loam', 'Alluvial Soil', 'Mixed Loam Soil', 'Black Soil', 'Clay Loam', 'Laterite Soil'])
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) {
                setState(() => _selectedSoilType = v);
                _saveData();
              },
              decoration: const InputDecoration(labelText: 'Soil Type'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: ['Kharif', 'Rabi', 'Summer'].contains(_selectedSeason)
                  ? _selectedSeason
                  : null,
              items: ['Kharif', 'Rabi', 'Summer']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedSeason = v);
                _saveData();
              },
              decoration: const InputDecoration(labelText: 'Season'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Field Area (hectare)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _previousIrrigationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Previous Irrigation (mm)'),
            ),
            const SizedBox(height: 12),
            // Button to fetch IoT and Weather Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchIoTAndWeatherData,
                icon: const Icon(Icons.refresh),
                label: const Text('Auto-fetch IoT & Weather Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sensor Data Section (Auto-populated from IoT)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensor Data (from IoT)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _temperatureController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Temperature (°C)',
                      suffixText: 'from IoT',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _humidityController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Humidity (%)',
                      suffixText: 'from IoT',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Weather Data Section (Auto-populated from Weather API)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Data (from API)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rainfallController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Rainfall (mm)',
                      suffixText: 'from Weather API',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sunlightController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Sunlight Hours',
                      suffixText: 'from Weather API',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _windSpeedController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Wind Speed (km/h)',
                      suffixText: 'from Weather API',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runPrediction,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Predict'),
              ),
            ),
            if (_predictionText != null) ...[
              const SizedBox(height: 12),
              Text(
                'Prediction:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _predictionText!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.green[800],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Save prediction as an event
                      await api.createIrrigationEvent(widget.token, {
                        'event_type': 'watered',
                        'details': _predictionText,
                      });
                      _loadRecentActivity();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Prediction'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runPrediction() async {
    if (_selectedCropType == null ||
        _selectedSoilType == null ||
        _selectedSeason == null ||
        _areaController.text.trim().isEmpty ||
        _previousIrrigationController.text.trim().isEmpty) {
      setState(() => _predictionText = 'Please fill required fields (Crop, Soil, Season, Area, Previous Irrigation)');
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionText = null;
    });

    final body = {
      'district': _districtController.text.trim(),
      'village': _villageController.text.trim(),
      'crop_type': _selectedCropType,
      'soil_type': _selectedSoilType,
      'season': _selectedSeason,
      'field_area_hectare': double.tryParse(_areaController.text) ?? 1.0,
      'previous_irrigation_mm': double.tryParse(_previousIrrigationController.text) ?? 0.0,
    };

    final res = await api.predictIrrigation(widget.token, body);
    setState(() {
      _isLoading = false;
    });

    if (res.containsKey('liters_required')) {
      setState(() {
        _predictionText =
            '${res['liters_required']} ${res['units'] ?? 'liters'}';
        _dayWiseRequirements = List<dynamic>.from(
          res['day_wise_requirements'] ?? [],
        );
      });
      _saveData();
    } else if (res.containsKey('prediction')) {
      setState(() {
        _predictionText = 'Prediction: ${jsonEncode(res['prediction'])}';
        _dayWiseRequirements = List<dynamic>.from(
          res['day_wise_requirements'] ?? [],
        );
      });
      _saveData();
    } else if (res.containsKey('success') && res['success'] == false) {
      setState(() {
        _predictionText = res['msg'] ?? 'Prediction failed';
        _dayWiseRequirements = [];
      });
      _saveData();
    } else if (res.containsKey('success') && res['success'] == true) {
      // Handle new response format with sensor data
      setState(() {
        final prediction = res['prediction'];
        _predictionText = 'Prediction: $prediction liters\n\nSensor Data:\n' +
            'Soil Moisture: ${res['sensor_data']?['soil_moisture']?.toStringAsFixed(1)}%\n' +
            'Temperature: ${res['sensor_data']?['temperature']?.toStringAsFixed(1)}°C\n' +
            'Humidity: ${res['sensor_data']?['humidity']?.toStringAsFixed(1)}%';
        _dayWiseRequirements = List<dynamic>.from(
          res['day_wise_requirements'] ?? [],
        );
      });
      _saveData();
    } else {
      setState(() {
        _predictionText = res.toString();
        _dayWiseRequirements = [];
      });
      _saveData();
    }
  }

  Widget _buildWaterUsageStats() {
    // compute totals from _waterUsage
    double today = 0, week = 0, month = 0;
    try {
      final now = DateTime.now();
      for (var item in _waterUsage) {
        final dateStr = item['date'];
        final liters = (item['liters'] ?? 0).toDouble();
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final diff = now.difference(d).inDays;
          if (diff == 0) today += liters;
          if (diff < 7) week += liters;
          if (diff < 30) month += liters;
        }
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Usage Statistics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Today',
                      '${today.toStringAsFixed(0)} L',
                      Icons.today,
                      AppTheme.infoColor,
                    ),
                    _buildStatItem(
                      'This Week',
                      '${week.toStringAsFixed(0)} L',
                      Icons.date_range,
                      AppTheme.primaryColor,
                    ),
                    _buildStatItem(
                      'This Month',
                      '${month.toStringAsFixed(0)} L',
                      Icons.calendar_month,
                      AppTheme.warningColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Efficiency',
                      '92%',
                      Icons.trending_up,
                      AppTheme.successColor,
                    ),
                    _buildStatItem(
                      'Savings',
                      '15%',
                      Icons.savings,
                      AppTheme.successColor,
                    ),
                    _buildStatItem(
                      'Cost',
                      '\$45',
                      Icons.attach_money,
                      AppTheme.errorColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPredictionDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day-wise Water Requirements',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Crop Type')),
                  DataColumn(label: Text('Area (acres)')),
                  DataColumn(label: Text('Soil Type')),
                  DataColumn(label: Text('Water (L)')),
                  DataColumn(label: Text('Duration (min)')),
                  DataColumn(label: Text('Rain %')),
                ],
                rows: _dayWiseRequirements.map<DataRow>((req) {
                  return DataRow(
                    cells: [
                      DataCell(Text(req['date'] ?? '')),
                      DataCell(Text(_selectedCropType ?? '')),
                      DataCell(Text(_areaController.text)),
                      DataCell(Text(_selectedSoilType ?? '')),
                      DataCell(
                        Text((req['water_liters'] ?? 0.0).toStringAsFixed(1)),
                      ),
                      DataCell(Text((req['duration_minutes'] ?? 0).toString())),
                      DataCell(Text('${req['precipitation_percent'] ?? 0}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recentEvents.isNotEmpty
                  ? _recentEvents
                        .map<Widget>(
                          (e) => Column(
                            children: [
                              _buildActivityItem(
                                e['details'] ?? e['type'] ?? 'Activity',
                                e['timestamp'] ?? '',
                                Icons.water_drop,
                                AppTheme.infoColor,
                              ),
                              const Divider(),
                            ],
                          ),
                        )
                        .toList()
                  : [
                      _buildActivityItem(
                        'No recent activity',
                        '',
                        Icons.info,
                        AppTheme.infoColor,
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listeners to controllers for saving data on changes
    _districtController.addListener(_saveData);
    _villageController.addListener(_saveData);
    _areaController.addListener(_saveData);
    _temperatureController.addListener(_saveData);
    _rainfallController.addListener(_saveData);
    _dayAfterSowingController.addListener(_saveData);
    _previousIrrigationController.addListener(_saveData);
    // Load data
    _loadSavedData();
    _fetchProfile();
    _loadIrrigationMetadata();
    _loadWaterUsage();
    _loadRecentActivity();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _predictionText = prefs.getString(_predictionTextKey);
      final dayWiseJson = prefs.getString(_dayWiseRequirementsKey);
      if (dayWiseJson != null) {
        try {
          _dayWiseRequirements = jsonDecode(dayWiseJson);
        } catch (_) {}
      }
      _selectedCropType = prefs.getString(_selectedCropTypeKey);
      _selectedSoilType = prefs.getString(_selectedSoilTypeKey);
      _selectedSeason = prefs.getString(_seasonKey);
      _districtController.text = prefs.getString(_districtKey) ?? '';
      _villageController.text = prefs.getString(_villageKey) ?? '';
      _areaController.text = prefs.getString(_areaKey) ?? '';
      _temperatureController.text = prefs.getString(_temperatureKey) ?? '28';
      _rainfallController.text = prefs.getString(_rainfallKey) ?? '5';
      _dayAfterSowingController.text =
          prefs.getString(_dayAfterSowingKey) ?? '1';
      _previousIrrigationController.text =
          prefs.getString(_previousIrrigationKey) ?? '0';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_predictionTextKey, _predictionText ?? '');
    await prefs.setString(
      _dayWiseRequirementsKey,
      jsonEncode(_dayWiseRequirements),
    );
    await prefs.setString(_selectedCropTypeKey, _selectedCropType ?? '');
    await prefs.setString(_selectedSoilTypeKey, _selectedSoilType ?? '');
    await prefs.setString(_seasonKey, _selectedSeason ?? '');
    await prefs.setString(_districtKey, _districtController.text);
    await prefs.setString(_villageKey, _villageController.text);
    await prefs.setString(_areaKey, _areaController.text);
    await prefs.setString(_temperatureKey, _temperatureController.text);
    await prefs.setString(_rainfallKey, _rainfallController.text);
    await prefs.setString(_dayAfterSowingKey, _dayAfterSowingController.text);
    await prefs.setString(_previousIrrigationKey, _previousIrrigationController.text);
  }
}
