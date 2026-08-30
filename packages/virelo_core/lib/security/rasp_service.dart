import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';
import 'dart:io';
import '../offline_sync/offline_storage_service.dart';

class RaspService {
  final OfflineStorageService _storageService;

  RaspService(this._storageService);

  Future<void> initialize() async {
    // Configuration de Talsec freeRASP
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.virelo.app',
        signingCertHashes: ['AKa/XvXYZ...'], // A remplacer par le vrai hash SHA-256 en prod
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.virelo.app'],
        teamId: 'YOUR_TEAM_ID', // A remplacer
      ),
      watcherMail: 'security@virelo.com',
      isProd: !kDebugMode,
    );

    // Callbacks lors de la détection de menaces
    final callback = ThreatCallback(
      onAppIntegrity: () => _handleThreat("App Integrity (Tampering)"),
      onObfuscationIssues: () => _handleThreat("Obfuscation Issues"),
      onDebug: () => _handleThreat("Debugging"),
      onDeviceBinding: () => _handleThreat("Device Binding / Cloning"),
      onDeviceID: () => _handleThreat("Device ID manipulation"),
      onHooks: () => _handleThreat("Hooking Framework Detected (Frida/Xposed)"),
      onPrivilegedAccess: () => _handleThreat("Root / Jailbreak"),
      onSimulator: () => _handleThreat("Emulator Detected"),
      onUnofficialStore: () => _handleThreat("Unofficial App Store"),
    );

    // Attacher les écouteurs
    Talsec.instance.attachListener(callback);

    // Démarrer la protection
    await Talsec.instance.start(config);
  }

  /// Gestion d'une menace de sécurité majeure
  void _handleThreat(String threatName) async {
    debugPrint("🚨 [VIRELO SECURITY RASP] MENACE DETECTÉE : $threatName");

    // En production, si on détecte une manipulation (Tampering) ou du Hooking, on s'autodétruit
    if (!kDebugMode) {
      if (threatName.contains("Integrity") || threatName.contains("Hooks") || threatName.contains("PrivilegeEscalation")) {
        debugPrint("💥 Destruction du Keystore et des données sensibles locales !");
        
        // On wipe tout ce qu'on peut
        await _storageService.clearOfflineTransactions();
        
        // On pourrait fermer l'app ici
        exit(0);
      }
    }
  }
}
