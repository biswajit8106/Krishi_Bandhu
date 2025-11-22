import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CropDiseaseScreen extends StatefulWidget {
  final String token;
  const CropDiseaseScreen({super.key, required this.token});

  @override
  State<CropDiseaseScreen> createState() => _CropDiseaseScreenState();
}

class _CropDiseaseScreenState extends State<CropDiseaseScreen> {
  final ApiService apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? prediction;
  bool loading = false;
  String? selectedCrop;
  List<String> availableCrops = [];
  double? confidence;

  @override
  void initState() {
    super.initState();
    fetchAvailableCrops();
  }

  Future<void> fetchAvailableCrops() async {
    final res = await apiService.getAvailableCrops();
    if (res["crops"] != null) {
      setState(() {
        availableCrops = List<String>.from(res["crops"]);
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        prediction = null;
        confidence = null;
      });
      if (selectedCrop != null) {
        uploadAndPredict();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a crop first")),
        );
      }
    }
  }

  Future<void> uploadAndPredict() async {
    if (_imageFile == null || selectedCrop == null) return;
    setState(() => loading = true);

    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final res = await apiService.predictDisease(widget.token, selectedCrop!, base64Image);

    setState(() {
      prediction = res["data"] != null ? res["data"]["prediction"] : "Could not detect disease";
      double? conf = res["data"] != null ? (res["data"]["confidence"] as num?)?.toDouble() : null;
      confidence = conf;
      loading = false;
    });
  }

  Widget _buildConfidenceIndicator() {
    if (confidence == null) return SizedBox.shrink();

    if (confidence! < 0.6) {
      return const Text(
        'Low confidence in the prediction',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    return Text(
      'Confidence: ${(confidence! * 100).toStringAsFixed(2)}%',
      style: const TextStyle(color: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crop Disease Detection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Crop Selection Dropdown
            DropdownButtonFormField<String>(
              value: selectedCrop,
              hint: const Text("Select Crop"),
              items: availableCrops.map((crop) {
                return DropdownMenuItem(
                  value: crop,
                  child: Text(crop.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCrop = value;
                  prediction = null; // Reset prediction when crop changes
                  confidence = null;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Crop Type",
              ),
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 250),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: selectedCrop != null ? () => pickImage(ImageSource.camera) : null,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                      ElevatedButton.icon(
                        onPressed: selectedCrop != null ? () => pickImage(ImageSource.gallery) : null,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            if (prediction != null) ...[
              Text(
                "Prediction: $prediction",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildConfidenceIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
