import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../widgets/disease_result_card.dart';
import '../widgets/camera_button.dart';
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

  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();

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
              _buildImageSection(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor.withOpacity(0.1), AppTheme.warningColor.withOpacity(0.1)],
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
          const Icon(
            Icons.eco,
            size: 50,
            color: AppTheme.errorColor,
          ),
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
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
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
                _buildDiseaseItem('Rice Blast', 'Fungal disease affecting rice leaves', Icons.warning, AppTheme.errorColor),
                const Divider(),
                _buildDiseaseItem('Powdery Mildew', 'White powdery coating on leaves', Icons.cloud, AppTheme.warningColor),
                const Divider(),
                _buildDiseaseItem('Leaf Spot', 'Dark spots on plant leaves', Icons.circle, AppTheme.infoColor),
                const Divider(),
                _buildDiseaseItem('Root Rot', 'Decay of plant roots', Icons.water_drop, AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseItem(String name, String description, IconData icon, Color color) {
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
                _buildTipItem('Maintain field hygiene', Icons.cleaning_services),
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
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
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
      final result = await apiService.predictDisease(widget.token, base64Image);
      setState(() {
        _isAnalyzing = false;
        _diseaseResults = [DiseaseResult(
          diseaseName: result['disease_name'] ?? 'Unknown Disease',
          confidence: (result['confidence'] ?? 0.0) * 100,
          description: result['description'] ?? 'No description available',
          symptoms: List<String>.from(result['symptoms'] ?? []),
          treatment: result['treatment'] ?? 'No treatment information available',
          severity: result['severity'] ?? 'Unknown',
        )];
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan History', style: GoogleFonts.poppins()),
        content: Text('No previous scans found.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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

  DiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.severity,
  });
}
