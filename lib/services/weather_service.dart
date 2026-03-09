import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherData {
  final String condition;
  final double temperature;
  final String city;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.city,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      condition: json['weather'][0]['main'],
      temperature: (json['main']['temp'] as num).toDouble(),
      city: json['name'],
    );
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static final String _apiKey = dotenv.get(
    'OPEN_WEATHER_API_KEY',
    fallback: '',
  );

  final ValueNotifier<WeatherData?> currentWeather =
      ValueNotifier<WeatherData?>(null);

  Future<WeatherData> fetchWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition();

    // If API Key is not set, return mock data but keep the location logic
    if (_apiKey.isEmpty) {
      final mockWeather = WeatherData(
        condition: 'Rainy',
        temperature: 24.0,
        city: 'Colombo',
      );
      currentWeather.value = mockWeather;
      return mockWeather;
    }

    // Actual API Call
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = WeatherData.fromJson(json.decode(response.body));
        currentWeather.value = data;
        return data;
      } else {
        currentWeather.value = null;
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      currentWeather.value = null;
      rethrow;
    }
  }
}

