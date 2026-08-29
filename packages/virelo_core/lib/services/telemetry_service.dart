import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../network/api_client.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();

  Future<void> sendTerminalPing({String? terminalIdentifier}) async {
    try {
      // 1. Get or determine terminal identifier
      String? identifier = terminalIdentifier;
      if (identifier == null || identifier.isEmpty) {
        identifier = await _storage.read(key: 'terminal_identifier');
      }
      
      // Si aucun identifiant n'est encore stocké, on prend l'ID device ou défaut
      identifier ??= 'TERM-MOBILE';

      // 2. Request Location permission & capture GPS
      Position? position;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        }
      }

      // 3. Get Device Model
      String deviceModel = 'Smartphone SoftPOS';
      try {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceModel = '${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceModel = iosInfo.utsname.machine;
        }
      } catch (_) {}

      // 4. Send ping to backend
      final payload = {
        'terminal_identifier': identifier,
        'latitude': position?.latitude ?? 5.3484,
        'longitude': position?.longitude ?? -4.0152,
        'device_model': deviceModel,
        'battery_level': 85,
        'location_name': position != null ? 'Position GPS Réelle' : 'Abidjan, Côte d’Ivoire',
      };

      await _apiClient.dio.post('/sync/terminal-ping', data: payload);
      if (kDebugMode) {
        print('📡 [Telemetry] Ping sent successfully: $payload');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Telemetry] Error sending ping: $e');
      }
    }
  }
}
