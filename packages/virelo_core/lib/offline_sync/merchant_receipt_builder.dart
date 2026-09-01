import '../crypto/offline_crypto_service.dart';
import '../network/api_client.dart';
import '../services/auth_service.dart';
import 'offline_authorization_payload.dart';
import 'offline_storage_service.dart';

/// Contre-reçu marchand (non-répudiation symétrique) pour les paiements
/// hors-ligne. Entièrement additif : si quoi que ce soit échoue, on renvoie
/// le payload client inchangé — un paiement offline-first ne doit jamais être
/// bloqué par l'absence de contre-reçu.
class MerchantReceiptBuilder {
  /// Renvoie le payload client augmenté de `merchantSignature`,
  /// `merchantPublicKey` et `merchantReceiptTimestamp` quand c'est possible.
  static Future<Map<String, dynamic>> augment(
    OfflineAuthorizationPayload clientPayload,
  ) async {
    final base = Map<String, dynamic>.from(clientPayload.toJson());
    try {
      final auth = AuthService(ApiClient());
      final merchantId = await auth.getUserId();
      if (merchantId == null || merchantId.isEmpty) return base;

      final crypto = OfflineCryptoService(OfflineStorageService(auth));
      await crypto.initializeKeys();

      final ts = DateTime.now().toUtc().toIso8601String();
      final res = await crypto.signMerchantReceipt(
        clientDataToSign: clientPayload.getDataToSign(),
        merchantId: merchantId,
        merchantTimestamp: ts,
      );

      base['merchantSignature'] = res['signature'];
      base['merchantPublicKey'] = res['publicKey'];
      base['merchantReceiptTimestamp'] = ts;
      return base;
    } catch (_) {
      return base;
    }
  }

  /// Enregistre (idempotent) la clé publique Ed25519 du device marchand côté
  /// serveur. À appeler quand le marchand est en ligne (ex. ouverture du
  /// tableau de bord). Silencieux en cas d'échec réseau.
  static Future<void> registerKeyIfOnline() async {
    try {
      final auth = AuthService(ApiClient());
      final crypto = OfflineCryptoService(OfflineStorageService(auth));
      await crypto.initializeKeys();
      final pk = await crypto.getPublicKey();
      if (pk == null || pk.isEmpty) return;
      await ApiClient().dio.post(
        '/terminal/register-key',
        data: {'merchant_public_key': pk},
      );
    } catch (_) {
      // hors-ligne / non-marchand : on réessaiera plus tard
    }
  }
}
