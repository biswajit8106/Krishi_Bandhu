class IrrigationZone {
  final String id;
  final String name;
  final int moistureLevel;
  final bool isActive;
  final DateTime lastWatered;
  final double waterFlowRate;
  final String cropType;
  final double area;
  final String location;

  IrrigationZone({
    required this.id,
    required this.name,
    required this.moistureLevel,
    required this.isActive,
    required this.lastWatered,
    required this.waterFlowRate,
    required this.cropType,
    required this.area,
    required this.location,
  });

  factory IrrigationZone.fromJson(Map<String, dynamic> json) {
    return IrrigationZone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      moistureLevel: json['moistureLevel'] ?? 0,
      isActive: json['isActive'] ?? false,
      lastWatered: DateTime.parse(json['lastWatered'] ?? DateTime.now().toIso8601String()),
      waterFlowRate: (json['waterFlowRate'] ?? 0).toDouble(),
      cropType: json['cropType'] ?? '',
      area: (json['area'] ?? 0).toDouble(),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'moistureLevel': moistureLevel,
      'isActive': isActive,
      'lastWatered': lastWatered.toIso8601String(),
      'waterFlowRate': waterFlowRate,
      'cropType': cropType,
      'area': area,
      'location': location,
    };
  }

  IrrigationZone copyWith({
    String? id,
    String? name,
    int? moistureLevel,
    bool? isActive,
    DateTime? lastWatered,
    double? waterFlowRate,
    String? cropType,
    double? area,
    String? location,
  }) {
    return IrrigationZone(
      id: id ?? this.id,
      name: name ?? this.name,
      moistureLevel: moistureLevel ?? this.moistureLevel,
      isActive: isActive ?? this.isActive,
      lastWatered: lastWatered ?? this.lastWatered,
      waterFlowRate: waterFlowRate ?? this.waterFlowRate,
      cropType: cropType ?? this.cropType,
      area: area ?? this.area,
      location: location ?? this.location,
    );
  }
}

class IrrigationSchedule {
  final String id;
  final String time;
  final List<String> zoneIds;
  final int durationMinutes;
  final bool isEnabled;
  final String frequency;
  final DateTime createdAt;
  final DateTime? lastExecuted;

  IrrigationSchedule({
    required this.id,
    required this.time,
    required this.zoneIds,
    required this.durationMinutes,
    required this.isEnabled,
    required this.frequency,
    required this.createdAt,
    this.lastExecuted,
  });

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    return IrrigationSchedule(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      zoneIds: List<String>.from(json['zoneIds'] ?? []),
      durationMinutes: json['durationMinutes'] ?? 0,
      isEnabled: json['isEnabled'] ?? false,
      frequency: json['frequency'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastExecuted: json['lastExecuted'] != null 
          ? DateTime.parse(json['lastExecuted'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'zoneIds': zoneIds,
      'durationMinutes': durationMinutes,
      'isEnabled': isEnabled,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
    };
  }

  IrrigationSchedule copyWith({
    String? id,
    String? time,
    List<String>? zoneIds,
    int? durationMinutes,
    bool? isEnabled,
    String? frequency,
    DateTime? createdAt,
    DateTime? lastExecuted,
  }) {
    return IrrigationSchedule(
      id: id ?? this.id,
      time: time ?? this.time,
      zoneIds: zoneIds ?? this.zoneIds,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
    );
  }
}

class WaterUsageStats {
  final double todayUsage;
  final double weeklyUsage;
  final double monthlyUsage;
  final double efficiency;
  final double savings;
  final double cost;
  final DateTime lastUpdated;

  WaterUsageStats({
    required this.todayUsage,
    required this.weeklyUsage,
    required this.monthlyUsage,
    required this.efficiency,
    required this.savings,
    required this.cost,
    required this.lastUpdated,
  });

  factory WaterUsageStats.fromJson(Map<String, dynamic> json) {
    return WaterUsageStats(
      todayUsage: (json['todayUsage'] ?? 0).toDouble(),
      weeklyUsage: (json['weeklyUsage'] ?? 0).toDouble(),
      monthlyUsage: (json['monthlyUsage'] ?? 0).toDouble(),
      efficiency: (json['efficiency'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayUsage': todayUsage,
      'weeklyUsage': weeklyUsage,
      'monthlyUsage': monthlyUsage,
      'efficiency': efficiency,
      'savings': savings,
      'cost': cost,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class PredictedIrrigationDay {
  final DateTime day;
  final int durationMinutes; // predicted irrigation duration in minutes
  final double waterLitres; // optional predicted water amount in litres

  PredictedIrrigationDay({
    required this.day,
    required this.durationMinutes,
    required this.waterLitres,
  });

  factory PredictedIrrigationDay.fromJson(Map<String, dynamic> json) {
    return PredictedIrrigationDay(
      day: DateTime.parse(json['day'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['durationMinutes'] ?? 0,
      waterLitres: (json['waterLitres'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.toIso8601String(),
      'durationMinutes': durationMinutes,
      'waterLitres': waterLitres,
    };
  }
}
