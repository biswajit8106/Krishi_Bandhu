class DiseaseResult {
  final String diseaseName;
  final double confidence;
  final String description;
  final List<String> symptoms;
  final String treatment;
  final String severity;
  final String imagePath;
  final DateTime detectedAt;
  final String cropType;
  final List<String> preventionTips;

  DiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.severity,
    required this.imagePath,
    required this.detectedAt,
    required this.cropType,
    required this.preventionTips,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      diseaseName: json['diseaseName'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatment: json['treatment'] ?? '',
      severity: json['severity'] ?? '',
      imagePath: json['imagePath'] ?? '',
      detectedAt: DateTime.parse(json['detectedAt'] ?? DateTime.now().toIso8601String()),
      cropType: json['cropType'] ?? '',
      preventionTips: List<String>.from(json['preventionTips'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'description': description,
      'symptoms': symptoms,
      'treatment': treatment,
      'severity': severity,
      'imagePath': imagePath,
      'detectedAt': detectedAt.toIso8601String(),
      'cropType': cropType,
      'preventionTips': preventionTips,
    };
  }
}

class CropDisease {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatments;
  final List<String> preventionMethods;
  final String severity;
  final String affectedCrops;
  final String season;
  final String imageUrl;

  CropDisease({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.symptoms,
    required this.causes,
    required this.treatments,
    required this.preventionMethods,
    required this.severity,
    required this.affectedCrops,
    required this.season,
    required this.imageUrl,
  });

  factory CropDisease.fromJson(Map<String, dynamic> json) {
    return CropDisease(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: List<String>.from(json['causes'] ?? []),
      treatments: List<String>.from(json['treatments'] ?? []),
      preventionMethods: List<String>.from(json['preventionMethods'] ?? []),
      severity: json['severity'] ?? '',
      affectedCrops: json['affectedCrops'] ?? '',
      season: json['season'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'symptoms': symptoms,
      'causes': causes,
      'treatments': treatments,
      'preventionMethods': preventionMethods,
      'severity': severity,
      'affectedCrops': affectedCrops,
      'season': season,
      'imageUrl': imageUrl,
    };
  }
}

class ScanHistory {
  final String id;
  final String imagePath;
  final List<DiseaseResult> results;
  final DateTime scannedAt;
  final String location;
  final String cropType;
  final String notes;

  ScanHistory({
    required this.id,
    required this.imagePath,
    required this.results,
    required this.scannedAt,
    required this.location,
    required this.cropType,
    required this.notes,
  });

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'] ?? '',
      imagePath: json['imagePath'] ?? '',
      results: (json['results'] as List<dynamic>?)
          ?.map((result) => DiseaseResult.fromJson(result))
          .toList() ?? [],
      scannedAt: DateTime.parse(json['scannedAt'] ?? DateTime.now().toIso8601String()),
      location: json['location'] ?? '',
      cropType: json['cropType'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'results': results.map((result) => result.toJson()).toList(),
      'scannedAt': scannedAt.toIso8601String(),
      'location': location,
      'cropType': cropType,
      'notes': notes,
    };
  }
}
