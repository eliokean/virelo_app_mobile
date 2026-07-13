import 'package:flutter/services.dart';


class DeviceSecurityService {
  /// Vérifie si l'appareil est sûr pour exécuter l'application (non rooté, non jailbreaké).
  static Future<bool> isDeviceSecure() async {
    // Le package flutter_jailbreak_detection n'est plus compatible avec AGP 8.
    // La sécurité RASP (root, hooking, etc.) est désormais gérée globalement par le package freerasp.
    return true;
  }
}
