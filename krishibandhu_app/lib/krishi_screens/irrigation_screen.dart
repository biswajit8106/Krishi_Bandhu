import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/irrigation_schedule_card.dart';
import '../widgets/weather_info_card.dart';
import '../models/irrigation_models.dart';
import '../services/api_service.dart';

class IrrigationScreen extends StatefulWidget {
  final String token;
  const IrrigationScreen({super.key, required this.token});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  // irrigation status and controls removed per request
  // dynamic metadata from backend
  List<String> _cropTypes = [];
  List<String> _soilTypes = [];
  List<dynamic> _waterUsage = [];
  List<dynamic> _recentEvents = [];
  // Form controllers
  final ApiService api = ApiService();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController(text: '28');
  final TextEditingController _rainfallController = TextEditingController(text: '5');
  final TextEditingController _dayAfterSowingController = TextEditingController(text: '1');
  String? _selectedCropType;
  String? _selectedSoilType;

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


  Future<void> _loadIrrigationMetadata() async {
    final meta = await api.getIrrigationMetadata();
    if (meta != null && meta is Map) {
      setState(() {
        _cropTypes = List<String>.from(meta['crops'] ?? []);
        _soilTypes = List<String>.from(meta['soils'] ?? []);
      });
    }
  }

  Future<void> _loadWaterUsage() async {
    // replace token retrieval as appropriate in your app
    try {
      final res = await api.getWaterUsage(widget.token, days: 30);
      if (res['success'] == true) {
        setState(() { _waterUsage = res['data'] ?? []; });
      }
    } catch (_) {}
  }

  Future<void> _loadRecentActivity() async {
    try {
      final res = await api.getRecentIrrigationEvents(widget.token);
      if (res['success'] == true) {
        setState(() { _recentEvents = res['data'] ?? []; });
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
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await api.getProfile(widget.token);
      if (profile != null && profile is Map && profile.containsKey('email')) {
        setState(() {
          _districtController.text = profile['district'] ?? '';
          _villageController.text = profile['location'] ?? profile['village'] ?? '';
        });
        // Fetch weather after profile is loaded
        await _fetchWeather();
      }
    } catch (_) {}
  }

  Future<void> _fetchWeather() async {
    try {
      final city = _villageController.text.trim().isNotEmpty ? _villageController.text : _districtController.text.trim();
      if (city.isEmpty) return;

      final data = await api.predictClimate(widget.token);
      if (data != null && data is Map && !data.containsKey('msg') && !data.containsKey('detail') && !(data.containsKey('success') && data['success'] == false)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Irrigation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildSchedule(),
        ],
      ),
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
            Text('Irrigation Prediction', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'District')),
            const SizedBox(height: 8),
            TextField(controller: _villageController, decoration: const InputDecoration(labelText: 'Village/City')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCropType,
              items: (_cropTypes.isNotEmpty ? _cropTypes : ['Rice', 'Wheat', 'Maize', 'Vegetables', 'Orchard']).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                setState(() => _selectedCropType = v);
                _saveData();
              },
              decoration: const InputDecoration(labelText: 'Crop Type'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSoilType,
              items: (_soilTypes.isNotEmpty ? _soilTypes : ['Sandy', 'Clay', 'Loam', 'Silt', 'Peaty']).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                setState(() => _selectedSoilType = v);
                _saveData();
              },
              decoration: const InputDecoration(labelText: 'Soil Type'),
            ),
            const SizedBox(height: 8),
            TextField(controller: _areaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area (acres)')),
            const SizedBox(height: 8),
            TextField(controller: _temperatureController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temperature (°C)')),
            const SizedBox(height: 8),
            TextField(controller: _rainfallController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rainfall (mm)')),
            const SizedBox(height: 8),
            TextField(controller: _dayAfterSowingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Day After Sowing')),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runPrediction,
                child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Predict'),
              ),
            ),
            if (_predictionText != null) ...[
              const SizedBox(height: 12),
              Text('Prediction:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(_predictionText!, style: GoogleFonts.poppins(fontSize: 16, color: Colors.green[800])),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Save prediction as an event
                      await api.createIrrigationEvent(widget.token, {
                        'event_type': 'prediction_saved',
                        'details': _predictionText,
                      });
                      _loadRecentActivity();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Prediction'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      if (_predictionText == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run prediction first')));
                        return;
                      }
                      setState(() { _isLoading = true; });

                      // Try to decode a prediction object; if _predictionText is JSON, parse it, otherwise try to extract a number
                      Map<String, dynamic>? parsedPrediction;
                      try {
                        final p = jsonDecode(_predictionText!);
                        if (p is Map<String, dynamic>) parsedPrediction = p;
                      } catch (_) {
                        parsedPrediction = null;
                      }

                      double? liters;
                      if (parsedPrediction != null) {
                        if (parsedPrediction['liters_required'] != null) liters = (parsedPrediction['liters_required'] as num).toDouble();
                        else if (parsedPrediction['liters'] != null) liters = (parsedPrediction['liters'] as num).toDouble();
                      }
                      if (liters == null) {
                        // try to extract number from the text (e.g. "1980.0 liters")
                        final m = RegExp(r"([0-9]+(?:\.[0-9]+)?)").firstMatch(_predictionText!);
                        if (m != null) liters = double.tryParse(m.group(1)!);
                      }

                      final body = {
                        'prediction': {'liters_required': liters ?? 0.0, 'units': 'liters'},
                        'weather': null,
                        'crop_type': _selectedCropType,
                        'soil_type': _selectedSoilType,
                        'area': double.tryParse(_areaController.text) ?? 1.0
                      };

                      final res = await api.generateAISchedule(widget.token, body);
                      setState(() { _isLoading = false; });

                      if (res != null && res is Map && res['success'] == true) {
                        // Backend may return the persisted schedules under 'created_schedules'
                        // or return a planner 'plan' with schedules. Prefer created_schedules
                        final plan = res['plan'] ?? {};
                        final created = res['created_schedules'] ?? [];
                        final schedules = (created is List && created.isNotEmpty) ? created : (plan['schedules'] ?? []);

                        // update recent activity and water usage and refresh saved schedules
                        _loadRecentActivity();
                        _loadWaterUsage();
                        _loadSchedules();

                        if (schedules is List && schedules.isNotEmpty) {
                          // Convert entire planner 'schedules' into PredictedIrrigationDay list (day-wise)
                          final List<PredictedIrrigationDay> predictedDays = schedules.map<PredictedIrrigationDay>((s) {
                            DateTime day;
                            try {
                              day = DateTime.parse(s['date'].toString());
                            } catch (_) {
                              day = DateTime.now();
                            }
                            // Try to extract minutes from duration string like '15 minutes' or '15 min'
                            int minutes = 0;
                            final dur = s['duration']?.toString() ?? '';
                            final m = RegExp(r"(\d+)").firstMatch(dur);
                            if (m != null) {
                              minutes = int.tryParse(m.group(0) ?? '0') ?? 0;
                            }
                            final water = (s['water_liters'] is num) ? (s['water_liters'] as num).toDouble() : 0.0;
                            return PredictedIrrigationDay(day: day, durationMinutes: minutes, waterLitres: water);
                          }).toList();

                          // Group schedules by date (if date present)
                          final Map<String, List<dynamic>> grouped = {};
                          for (var s in schedules) {
                            final date = (s is Map && s['date'] != null) ? s['date'].toString() : 'Plan';
                            grouped.putIfAbsent(date, () => []).add(s);
                          }

                          // Show day-wise plan in a bottom sheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) {
                              return DraggableScrollableSheet(
                                expand: false,
                                builder: (_, controller) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: ListView(
                                      controller: controller,
                                      children: grouped.keys.map((date) {
                                        final items = grouped[date]!;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(date, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            ...items.map<Widget>((it) {
                                              final time = it['time'] ?? '';
                                              final duration = it['duration'] ?? '';
                                              final litersVal = it['water_liters'] != null ? (it['water_liters'] as num).toDouble() : null;
                                              final litersStr = litersVal != null ? '${litersVal.toStringAsFixed(1)} L' : '';
                                              final enabled = it['is_enabled'] == true;

                                              return Column(
                                                children: [
                                                  IrrigationScheduleCard(
                                                    time: '$time ${litersStr.isNotEmpty ? "• $litersStr" : ''}',
                                                    duration: duration.toString(),
                                                    isEnabled: enabled,
                                                    onToggle: (v) {},
                                                    predictedPlan: predictedDays,
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                              );
                                            }).toList(),
                                            const SizedBox(height: 12),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No schedules returned by planner')));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res != null && res['msg'] != null ? res['msg'].toString() : 'Failed to generate schedule')));
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Generate AI Schedule'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _runPrediction() async {
    if (_selectedCropType == null || _selectedSoilType == null || _areaController.text.trim().isEmpty || _temperatureController.text.trim().isEmpty || _rainfallController.text.trim().isEmpty || _dayAfterSowingController.text.trim().isEmpty) {
      setState(() => _predictionText = 'Please fill required fields');
      return;
    }

    setState(() { _isLoading = true; _predictionText = null; });

    final body = {
      'district': _districtController.text.trim(),
      'village': _villageController.text.trim(),
      'crop_type': _selectedCropType,
      'soil_type': _selectedSoilType,
      'area': double.tryParse(_areaController.text) ?? 1.0,
      'temperature': double.tryParse(_temperatureController.text) ?? 28.0,
      'rainfall': double.tryParse(_rainfallController.text) ?? 5.0,
      'day_after_sowing': int.tryParse(_dayAfterSowingController.text) ?? 1,
    };

    final res = await api.predictIrrigation(widget.token, body);
    setState(() { _isLoading = false; });

    if (res == null) {
      setState(() => _predictionText = 'No response from server');
      return;
    }

    if (res is Map && res.containsKey('liters_required')) {
      setState(() {
        _predictionText = '${res['liters_required']} ${res['units'] ?? 'liters'}';
        _dayWiseRequirements = List<dynamic>.from(res['day_wise_requirements'] ?? []);
      });
      _saveData();
    } else if (res is Map && res.containsKey('prediction')) {
      setState(() {
        _predictionText = jsonEncode(res['prediction']);
        _dayWiseRequirements = List<dynamic>.from(res['day_wise_requirements'] ?? []);
      });
      _saveData();
    } else if (res is Map && res.containsKey('success') && res['success'] == false) {
      setState(() {
        _predictionText = res['msg'] ?? 'Prediction failed';
        _dayWiseRequirements = [];
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

  Widget _buildIrrigationStatus() {
    // Irrigation status block removed.
    return const SizedBox.shrink();
  }

  Widget _buildQuickControls() {
    // Quick controls removed.
    return const SizedBox.shrink();
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    // Control buttons removed.
    return ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));
  }

  Widget _buildSoilMoistureChart() {
    // Soil moisture chart removed.
    return const SizedBox.shrink();
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
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
                    _buildStatItem('Today', '${today.toStringAsFixed(0)} L', Icons.today, AppTheme.infoColor),
                    _buildStatItem('This Week', '${week.toStringAsFixed(0)} L', Icons.date_range, AppTheme.primaryColor),
                    _buildStatItem('This Month', '${month.toStringAsFixed(0)} L', Icons.calendar_month, AppTheme.warningColor),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Efficiency', '92%', Icons.trending_up, AppTheme.successColor),
                    _buildStatItem('Savings', '15%', Icons.savings, AppTheme.successColor),
                    _buildStatItem('Cost', '\$45', Icons.attach_money, AppTheme.errorColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
                  return DataRow(cells: [
                    DataCell(Text(req['date'] ?? '')),
                    DataCell(Text(_selectedCropType ?? '')),
                    DataCell(Text(_areaController.text)),
                    DataCell(Text(_selectedSoilType ?? '')),
                    DataCell(Text((req['water_liters'] ?? 0.0).toStringAsFixed(1))),
                    DataCell(Text((req['duration_minutes'] ?? 0).toString())),
                    DataCell(Text('${req['precipitation_percent'] ?? 0}%')),
                  ]);
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
              children: _recentEvents.isNotEmpty ? _recentEvents.map<Widget>((e) => Column(
                children: [
                  _buildActivityItem(e['details'] ?? e['type'] ?? 'Activity', e['timestamp'] ?? '', Icons.water_drop, AppTheme.infoColor),
                  const Divider(),
                ],
              )).toList() : [
                _buildActivityItem('No recent activity', '', Icons.info, AppTheme.infoColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
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

  Widget _buildZones() {
    // Zones view removed.
    return const SizedBox.shrink();
  }

  // Track schedules state
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoadingSchedules = false;

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
    // Load schedules along with other data
    _loadSavedData();
    _fetchProfile();
    _loadIrrigationMetadata();
    _loadWaterUsage();
    _loadRecentActivity();
    _loadSchedules();
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
      _districtController.text = prefs.getString(_districtKey) ?? '';
      _villageController.text = prefs.getString(_villageKey) ?? '';
      _areaController.text = prefs.getString(_areaKey) ?? '';
      _temperatureController.text = prefs.getString(_temperatureKey) ?? '28';
      _rainfallController.text = prefs.getString(_rainfallKey) ?? '5';
      _dayAfterSowingController.text = prefs.getString(_dayAfterSowingKey) ?? '1';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_predictionTextKey, _predictionText ?? '');
    await prefs.setString(_dayWiseRequirementsKey, jsonEncode(_dayWiseRequirements));
    await prefs.setString(_selectedCropTypeKey, _selectedCropType ?? '');
    await prefs.setString(_selectedSoilTypeKey, _selectedSoilType ?? '');
    await prefs.setString(_districtKey, _districtController.text);
    await prefs.setString(_villageKey, _villageController.text);
    await prefs.setString(_areaKey, _areaController.text);
    await prefs.setString(_temperatureKey, _temperatureController.text);
    await prefs.setString(_rainfallKey, _rainfallController.text);
    await prefs.setString(_dayAfterSowingKey, _dayAfterSowingController.text);
  }

  Future<void> _loadSchedules() async {
    setState(() { _isLoadingSchedules = true; });
    try {
      final res = await api.getIrrigationSchedules(widget.token);
      if (res['success'] == true && res['data'] != null) {
        setState(() { _schedules = List<Map<String, dynamic>>.from(res['data']); });
      }
    } catch (_) {}
    setState(() { _isLoadingSchedules = false; });
  }

  Widget _buildSchedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Irrigation Schedule',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSchedules,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSchedules)
            const Center(child: CircularProgressIndicator())
          else if (_schedules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No schedules yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Use Predict & Generate AI Schedule to create schedules',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._buildDayWiseSchedules(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Switch to Dashboard tab for prediction
                _tabController.animateTo(0);
                // Scroll to prediction card (would need a ScrollController)
                // Or show a hint about using prediction
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use Predict & Generate AI Schedule to create new schedules'))
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayWiseSchedules() {
    // Group schedules by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var s in _schedules) {
      final date = s['date']?.toString() ?? 'Unscheduled';
      grouped.putIfAbsent(date, () => []).add(s);
    }

    // Sort dates
    final sortedDates = grouped.keys.toList()..sort();
    
    return sortedDates.expand((date) {
      final schedules = grouped[date]!;
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...schedules.map((s) {
          final time = s['time'] ?? '';
          final duration = s['duration'] ?? '';
          final liters = s['water_liters'];
          final litersStr = liters != null ? ' • ${liters.toStringAsFixed(1)} L' : '';
          final enabled = s['is_enabled'] == true;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IrrigationScheduleCard(
              time: '$time$litersStr',
              duration: duration,
              isEnabled: enabled,
              onToggle: (v) async {
                // Update schedule enabled state
                final body = Map<String, dynamic>.from(s)..['is_enabled'] = v;
                await api.createIrrigationSchedule(widget.token, body);
                _loadSchedules();  // Refresh list
              },
              // Demo predicted plan for this schedule (7 days)
              predictedPlan: List.generate(7, (i) {
                final baseDuration = int.tryParse(duration.toString()) ?? 0;
                final d = DateTime.now().add(Duration(days: i));
                final litersVal = (s['water_liters'] is num) ? (s['water_liters'] as num).toDouble() : 0.0;
                return PredictedIrrigationDay(
                  day: d,
                  durationMinutes: (baseDuration + i * 2),
                  waterLitres: litersVal + (i * 0.5),
                );
              }),
            ),
          );
        }).toList(),
      ];
    }).toList();
  }

  // Control and settings methods removed.
}
