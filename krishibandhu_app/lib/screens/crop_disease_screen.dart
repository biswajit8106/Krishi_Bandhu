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

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        prediction = null;
      });
      uploadAndPredict();
    }
  }

  Future<void> uploadAndPredict() async {
    if (_imageFile == null) return;
    setState(() => loading = true);

    final bytes = await _imageFile!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final res = await apiService.predictDisease(widget.token, base64Image);

    setState(() {
      prediction = res["prediction"] ?? "Could not detect disease";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crop Disease Detection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_imageFile != null)
              Image.file(_imageFile!, height: 250),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            if (prediction != null)
              Text(
                "Prediction: $prediction",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
