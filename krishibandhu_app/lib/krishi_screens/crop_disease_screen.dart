import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/disease_result_card.dart';
import '../widgets/camera_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class CropDiseaseScreen extends StatefulWidget {
  final String token;
  const CropDiseaseScreen({super.key, required this.token});

  @override
  State<CropDiseaseScreen> createState() => _CropDiseaseScreenState();
}

class _CropDiseaseScreenState extends State<CropDiseaseScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  List<DiseaseResult> _diseaseResults = [];
  String? _selectedCrop;

  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();

  final List<Map<String, String>> crops = [
    {
      "name": "Wheat",
      "asset": "lib/krishi_screens/assets/Wheat.png",
      "backend": "wheat",
    },
    {
      "name": "Rice",
      "asset": "lib/krishi_screens/assets/Rice.png",
      "backend": "rice",
    },
    {
      "name": "Maize",
      "asset": "lib/krishi_screens/assets/Maize.png",
      "backend": "corn",
    },
    {
      "name": "Sugarcane",
      "asset": "lib/krishi_screens/assets/Sugarcan.png",
      "backend": "sugarcane",
    },
    {
      "name": "Black Gram",
      "asset": "lib/krishi_screens/assets/Black Gram.png",
      "backend": "black_gram",
    },
    {
      "name": "Soybean",
      "asset": "lib/krishi_screens/assets/Soybean.png",
      "backend": "soybean",
    },
    {
      "name": "Potato",
      "asset": "lib/krishi_screens/assets/Potato.png",
      "backend": "potato",
    },
    {
      "name": "Tomato",
      "asset": "lib/krishi_screens/assets/Tamato.png",
      "backend": "tomato",
    },
    {
      "name": "Brinjal",
      "asset": "lib/krishi_screens/assets/Brinjal.png",
      "backend": "brinjal",
    },
    {
      "name": "Chilli",
      "asset": "lib/krishi_screens/assets/Chilli.png",
      "backend": "chilli",
    },
    {
      "name": "Apple",
      "asset": "lib/krishi_screens/assets/Apple.png",
      "backend": "apple",
    },
    {
      "name": "Banana",
      "asset": "lib/krishi_screens/assets/Banana.png",
      "backend": "banana",
    },
    {
      "name": "Grape",
      "asset": "lib/krishi_screens/assets/Grape.png",
      "backend": "grape",
    },
    {
      "name": "Cherry",
      "asset": "lib/krishi_screens/assets/Cherry.png",
      "backend": "cherry",
    },
    {
      "name": "Strawberry",
      "asset": "lib/krishi_screens/assets/Strawberry.png",
      "backend": "strawberry",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crop Disease Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showHistoryDialog();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCropSelection(),
              const SizedBox(height: 24),
              if (_selectedCrop != null) _buildImageSection(),
              const SizedBox(height: 24),
              if (_diseaseResults.isNotEmpty) _buildResultsSection(),
              const SizedBox(height: 24),
              _buildCommonDiseases(),
              const SizedBox(height: 24),
              _buildPreventionTips(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1, token: widget.token),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor.withOpacity(0.1),
            AppTheme.warningColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Disease Detection',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload crop images to identify diseases and get treatment recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.eco, size: 50, color: AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Crop Image',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImage == null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 50,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No image selected',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap below to select an image',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _diseaseResults.clear();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CameraButton(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CameraButton(
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeImage,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Disease'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCropSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select crops',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: crops.length,
          itemBuilder: (context, index) {
            final crop = crops[index];
            final isSelected = _selectedCrop == crop["name"];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCrop = crop["name"];
                  _selectedImage = null;
                  _diseaseResults.clear();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Image.asset(
                        crop["asset"]!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      crop["name"]!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ..._diseaseResults.map((result) => DiseaseResultCard(result: result)),
      ],
    );
  }

  Widget _buildCommonDiseases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Crop Diseases',
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
                GestureDetector(
                  onTap: () => _showRiceBlastDialog(),
                  child: _buildDiseaseItem(
                    'Rice Blast',
                    'Fungal disease affecting rice leaves',
                    Icons.warning,
                    AppTheme.errorColor,
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () => _showPowderyMildewDialog(),
                  child: _buildDiseaseItem(
                    'Powdery Mildew',
                    'White powdery coating on leaves',
                    Icons.cloud,
                    AppTheme.warningColor,
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () => _showLeafSpotDialog(),
                  child: _buildDiseaseItem(
                    'Leaf Spot',
                    'Dark spots on plant leaves',
                    Icons.circle,
                    AppTheme.infoColor,
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () => _showRootRotDialog(),
                  child: _buildDiseaseItem(
                    'Root Rot',
                    'Decay of plant roots',
                    Icons.water_drop,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseItem(
    String name,
    String description,
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
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildPreventionTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prevention Tips',
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
                _buildTipItem('Regular crop monitoring', Icons.visibility),
                _buildTipItem('Proper irrigation management', Icons.water_drop),
                _buildTipItem('Crop rotation practices', Icons.refresh),
                _buildTipItem('Use disease-resistant varieties', Icons.shield),
                _buildTipItem(
                  'Maintain field hygiene',
                  Icons.cleaning_services,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _diseaseResults.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Convert image to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Find the backend crop name
      final selectedCropData = crops.firstWhere(
        (crop) => crop["name"] == _selectedCrop,
        orElse: () => {"backend": _selectedCrop!.toLowerCase()},
      );
      final backendCrop =
          selectedCropData["backend"] ?? _selectedCrop!.toLowerCase();

      final result = await apiService.predictDisease(
        widget.token,
        backendCrop,
        base64Image,
      );

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction error: ${result['msg']}')),
        );
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      final data = result['data'];

      // Debug: print full response data so we can inspect recommendation/prevention values
      try {
        // ignore: avoid_print
        print('[CropDiseaseScreen] API response data: ' + data.toString());
      } catch (_) {}

      // Parse confidence from backend and normalize to percentage (0-100).
      double parsedConfidence = 0.0;
      try {
        final rawConf = data['confidence'];
        if (rawConf != null) {
          if (rawConf is num) {
            parsedConfidence = rawConf.toDouble();
          } else if (rawConf is String) {
            parsedConfidence = double.tryParse(rawConf) ?? 0.0;
          }

          // If model returns probability in [0,1], convert to percentage
          if (parsedConfidence <= 1.0) {
            parsedConfidence = parsedConfidence * 100.0;
          }
        }
      } catch (_) {
        parsedConfidence = 0.0;
      }

      // Clamp to sensible range
      parsedConfidence = parsedConfidence.clamp(0.0, 100.0);

      setState(() {
        _isAnalyzing = false;
        _diseaseResults = [
          DiseaseResult(
            diseaseName:
                'Predicted Class: ${data['predicted_class'] ?? data['prediction'] ?? 'Unknown'}',
            confidence: parsedConfidence,
            description: 'Disease predicted by AI model for ${_selectedCrop}',
            symptoms: ['Symptoms not available from model'],
            treatment:
                data['recommendation'] ??
                data['treatment'] ??
                'Consult local agricultural expert for treatment',
            prevention: data['prevention'] ?? '',
            recommendation: data['recommendation'] ?? '',
            severity: data['severity'] ?? 'Severity not determined',
          ),
        ];
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing image: $e')));
    }
  }

  Future<void> _showHistoryDialog() async {
    // show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final res = await apiService.getDiseaseHistory(widget.token);

    // hide loading
    Navigator.pop(context);

    // Debug: print response for troubleshooting
    try {
      // ignore: avoid_print
      print('[CropDiseaseScreen] getDiseaseHistory response: ' + res.toString());
    } catch (_) {}

    // If API returned a failure shape like {success: false, msg: ...}, show the message
    if (res is Map && res.containsKey('success') && res['success'] == false) {
      final msg = (res['msg'] is String) ? res['msg'] : 'Failed to load history.';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scan History', style: GoogleFonts.poppins()),
          content: Text(msg, style: GoogleFonts.poppins()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    if (res == null || res is! Map) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scan History', style: GoogleFonts.poppins()),
          content: Text('Failed to load history.', style: GoogleFonts.poppins()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    final List preds = (res['predictions'] is List) ? res['predictions'] : [];

    if (preds.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scan History', style: GoogleFonts.poppins()),
          content: Text('No previous scans found.', style: GoogleFonts.poppins()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan History', style: GoogleFonts.poppins()),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: preds.length,
            itemBuilder: (context, index) {
              final p = preds[index];
              // Parse confidence and convert to percentage if needed
              double confidence = 0.0;
              if (p['confidence'] is num) {
                confidence = (p['confidence'] as num).toDouble();
              } else if (p['confidence'] is String) {
                confidence = double.tryParse(p['confidence']) ?? 0.0;
              }
              // If confidence is in 0-1 range, convert to percentage
              if (confidence <= 1.0 && confidence > 0.0) {
                confidence = confidence * 100.0;
              }
              
              return ListTile(
                title: Text('${p['crop_type'] ?? ''} — ${p['predicted_class'] ?? ''}'),
                subtitle: Text('Confidence: ${confidence.toStringAsFixed(1)}%\n${p['created_at'] ?? ''}'),
                isThreeLine: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Prediction Details', style: GoogleFonts.poppins()),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Crop: ${p['crop_type'] ?? ''}', style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('Predicted: ${p['predicted_class'] ?? ''}', style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('Confidence: ${confidence.toStringAsFixed(1)}%', style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('Recommendation:\n${p['recommendation'] ?? ''}', style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('Prevention:\n${p['prevention'] ?? ''}', style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('Scanned at: ${p['created_at'] ?? ''}', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRiceBlastDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🌾 Rice Blast Disease (Short Explanation)',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rice Blast is a serious fungal disease caused by Magnaporthe oryzae. It affects rice leaves, stems, and panicles, creating grey, diamond-shaped spots. The disease weakens plants, reduces grain formation, and can cause major yield loss.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'It spreads quickly in warm, humid weather, especially with too much nitrogen fertilizer and crowded planting.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Control methods:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Use resistant rice varieties'),
              _buildBulletPoint('Maintain proper spacing'),
              _buildBulletPoint('Apply balanced fertilizers'),
              _buildBulletPoint('Remove infected debris'),
              _buildBulletPoint('Use recommended fungicides if needed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showPowderyMildewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🌱 Powdery Mildew Disease',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Powdery Mildew is a common fungal disease that affects many crops. It appears as white, powder-like spots on leaves, stems, and buds. As it spreads, the plant becomes weak, leaves turn yellow, and growth slows down.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'The disease spreads quickly in warm, dry climates with high humidity and poor airflow.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Control methods:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Use resistant varieties'),
              _buildBulletPoint('Improve air circulation by proper spacing'),
              _buildBulletPoint('Remove infected leaves'),
              _buildBulletPoint(
                'Apply recommended fungicides or organic sprays like neem or baking soda solutions',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showLeafSpotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🍃 Leaf Spot Disease',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leaf Spot Disease is caused by fungi or bacteria and leads to small brown, black, or yellow spots on plant leaves. As the spots grow, they may join together, causing the leaf to dry, turn yellow, and fall off early. This reduces the plant\'s ability to make food and can lower crop yield.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'The disease spreads easily in wet, humid conditions, especially when leaves stay moist for long periods.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Control methods:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Remove and destroy infected leaves'),
              _buildBulletPoint('Avoid overhead watering'),
              _buildBulletPoint('Ensure proper spacing for airflow'),
              _buildBulletPoint(
                'Use recommended fungicides or bactericides if needed',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showRootRotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🌿 Root Rot Disease',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Root Rot is a fungal disease that causes plant roots to decay, soften, and turn brown or black. Diseased roots cannot absorb water or nutrients, leading to wilting, yellowing leaves, stunted growth, and eventually plant death.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'It spreads easily in waterlogged, poorly drained soils or when plants are overwatered.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Control methods:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Improve soil drainage'),
              _buildBulletPoint('Avoid overwatering'),
              _buildBulletPoint('Use disease-free seeds or seedlings'),
              _buildBulletPoint('Apply recommended soil fungicides'),
              _buildBulletPoint('Practice crop rotation'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: Text('•', style: GoogleFonts.poppins(fontSize: 13)),
          ),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }
}

class DiseaseResult {
  final String diseaseName;
  final double confidence;
  final String description;
  final List<String> symptoms;
  final String treatment;
  final String severity;
  final String recommendation;
  final String prevention;

  DiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.severity,
    required this.recommendation,
    required this.prevention,
  });
}
