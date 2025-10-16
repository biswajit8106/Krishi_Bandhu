class WeatherData {
  final String location;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int uvIndex;
  final double visibility;
  final double dewPoint;
  final String condition;
  final String sunrise;
  final String sunset;
  final String moonPhase;
  final int airQuality;
  final DateTime timestamp;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.uvIndex,
    required this.visibility,
    required this.dewPoint,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    required this.moonPhase,
    required this.airQuality,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      feelsLike: (json['feelsLike'] ?? 0).toDouble(),
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      pressure: json['pressure'] ?? 0,
      uvIndex: json['uvIndex'] ?? 0,
      visibility: (json['visibility'] ?? 0).toDouble(),
      dewPoint: (json['dewPoint'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      moonPhase: json['moonPhase'] ?? '',
      airQuality: json['airQuality'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'pressure': pressure,
      'uvIndex': uvIndex,
      'visibility': visibility,
      'dewPoint': dewPoint,
      'condition': condition,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonPhase': moonPhase,
      'airQuality': airQuality,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WeatherForecast {
  final String day;
  final String date;
  final int highTemp;
  final int lowTemp;
  final String condition;
  final int precipitation;
  final double windSpeed;
  final int humidity;

  WeatherForecast({
    required this.day,
    required this.date,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      highTemp: json['highTemp'] ?? 0,
      lowTemp: json['lowTemp'] ?? 0,
      condition: json['condition'] ?? '',
      precipitation: json['precipitation'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      humidity: json['humidity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date,
      'highTemp': highTemp,
      'lowTemp': lowTemp,
      'condition': condition,
      'precipitation': precipitation,
      'windSpeed': windSpeed,
      'humidity': humidity,
    };
  }
}

class WeatherAlert {
  final String title;
  final String description;
  final String severity;
  final DateTime startTime;
  final DateTime endTime;
  final String type;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type,
    };
  }
}
