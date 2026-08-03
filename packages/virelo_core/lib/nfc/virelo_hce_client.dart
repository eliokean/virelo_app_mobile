import 'package:flutter/services.dart';

class VireloHceClient {
  static const MethodChannel _channel = MethodChannel('com.virelo.client/hce');

  /// Active l'émulation de carte NFC (Host Card Emulation) avec le jeton de paiement chiffré
  static Future<void> setPayload(String encryptedPayload) async {
    try {
      await _channel.invokeMethod('setPayload', {'payload': encryptedPayload});
    } catch (e) {
      // Silencieusement ignoré sur plateformes non-Android ou sans HCE
    }
  }

  /// Désactive l'émulation de carte et efface le jeton en mémoire
  static Future<void> clearPayload() async {
    try {
      await _channel.invokeMethod('clearPayload');
    } catch (e) {
      // Ignoré
    }
  }
}
