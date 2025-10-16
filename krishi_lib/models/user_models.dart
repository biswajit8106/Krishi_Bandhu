class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String membershipType;
  final DateTime createdAt;
  final DateTime lastLogin;
  final UserPreferences preferences;
  final FarmInfo farmInfo;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImageUrl,
    required this.membershipType,
    required this.createdAt,
    required this.lastLogin,
    required this.preferences,
    required this.farmInfo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      membershipType: json['membershipType'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(json['lastLogin'] ?? DateTime.now().toIso8601String()),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      farmInfo: FarmInfo.fromJson(json['farmInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'membershipType': membershipType,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'preferences': preferences.toJson(),
      'farmInfo': farmInfo.toJson(),
    };
  }
}

class UserPreferences {
  final String theme;
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool dataSyncEnabled;
  final String language;
  final String temperatureUnit;
  final String distanceUnit;

  UserPreferences({
    required this.theme,
    required this.notificationsEnabled,
    required this.locationEnabled,
    required this.dataSyncEnabled,
    required this.language,
    required this.temperatureUnit,
    required this.distanceUnit,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      locationEnabled: json['locationEnabled'] ?? true,
      dataSyncEnabled: json['dataSyncEnabled'] ?? true,
      language: json['language'] ?? 'en',
      temperatureUnit: json['temperatureUnit'] ?? 'celsius',
      distanceUnit: json['distanceUnit'] ?? 'metric',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'locationEnabled': locationEnabled,
      'dataSyncEnabled': dataSyncEnabled,
      'language': language,
      'temperatureUnit': temperatureUnit,
      'distanceUnit': distanceUnit,
    };
  }
}

class FarmInfo {
  final String farmName;
  final String location;
  final double totalArea;
  final int totalFields;
  final List<String> cropTypes;
  final String soilType;
  final String irrigationSystem;
  final DateTime establishedDate;

  FarmInfo({
    required this.farmName,
    required this.location,
    required this.totalArea,
    required this.totalFields,
    required this.cropTypes,
    required this.soilType,
    required this.irrigationSystem,
    required this.establishedDate,
  });

  factory FarmInfo.fromJson(Map<String, dynamic> json) {
    return FarmInfo(
      farmName: json['farmName'] ?? '',
      location: json['location'] ?? '',
      totalArea: (json['totalArea'] ?? 0).toDouble(),
      totalFields: json['totalFields'] ?? 0,
      cropTypes: List<String>.from(json['cropTypes'] ?? []),
      soilType: json['soilType'] ?? '',
      irrigationSystem: json['irrigationSystem'] ?? '',
      establishedDate: DateTime.parse(json['establishedDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'location': location,
      'totalArea': totalArea,
      'totalFields': totalFields,
      'cropTypes': cropTypes,
      'soilType': soilType,
      'irrigationSystem': irrigationSystem,
      'establishedDate': establishedDate.toIso8601String(),
    };
  }
}

class FarmStats {
  final double currentYield;
  final double waterSaved;
  final double efficiency;
  final int activeFields;
  final double totalProduction;
  final DateTime lastUpdated;

  FarmStats({
    required this.currentYield,
    required this.waterSaved,
    required this.efficiency,
    required this.activeFields,
    required this.totalProduction,
    required this.lastUpdated,
  });

  factory FarmStats.fromJson(Map<String, dynamic> json) {
    return FarmStats(
      currentYield: (json['currentYield'] ?? 0).toDouble(),
      waterSaved: (json['waterSaved'] ?? 0).toDouble(),
      efficiency: (json['efficiency'] ?? 0).toDouble(),
      activeFields: json['activeFields'] ?? 0,
      totalProduction: (json['totalProduction'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentYield': currentYield,
      'waterSaved': waterSaved,
      'efficiency': efficiency,
      'activeFields': activeFields,
      'totalProduction': totalProduction,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
