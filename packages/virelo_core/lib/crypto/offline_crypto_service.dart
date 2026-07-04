import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../offline_sync/offline_authorization_payload.dart';
import '../offline_sync/offline_storage_service.dart';

class OfflineCryptoService {
  final OfflineStorageService _storageService;
  final Ed25519 _algorithm = Ed25519();

  OfflineCryptoService(this._storageService);

  /// Initialise la paire de clés si elle n'existe pas déjà
  Future<void> initializeKeys() async {
    final existingKeyPair = await _storageService.getKeyPair(_algorithm);
    if (existingKeyPair == null) {
      final keyPair = await _algorithm.newKeyPair();
      await _storageService.saveKeyPair(keyPair);
    }
  }

  /// Retourne la clé publique en Base64 (pour l'envoyer au marchand ou pour le QR Code)
  Future<String?> getPublicKey() async {
    return await _storageService.getPublicKeyBase64();
  }

  /// Génère une promesse de débit signée pour un marchand
  Future<OfflineAuthorizationPayload> generateSignedPayload({
    required String clientId,
    required String merchantId,
    required double amount,
  }) async {
    final keyPair = await _storageService.getKeyPair(_algorithm);
    if (keyPair == null) {
      throw Exception("Clés cryptographiques non initialisées");
    }

    final sequenceNumber = await _storageService.incrementAndGetSequenceNumber();
    final timestamp = DateTime.now().toIso8601String();
    final publicKeyBase64 = await getPublicKey() ?? '';

    // On prépare le payload sans la signature
    final payloadWithoutSig = OfflineAuthorizationPayload(
      clientId: clientId,
      merchantId: merchantId,
      amount: amount,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      clientPublicKey: publicKeyBase64,
      clientSignature: '', // Sera rempli juste après
    );

    // On signe les données
    final dataToSign = utf8.encode(payloadWithoutSig.getDataToSign());
    final signature = await _algorithm.sign(dataToSign, keyPair: keyPair);
    
    // On retourne le payload complet
    return OfflineAuthorizationPayload(
      clientId: clientId,
      merchantId: merchantId,
      amount: amount,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      clientPublicKey: publicKeyBase64,
      clientSignature: base64Encode(signature.bytes),
    );
  }

  /// Vérifie la validité d'une signature (Côté Marchand)
  Future<bool> verifyPayload(OfflineAuthorizationPayload payload) async {
    final publicKeyBytes = base64Decode(payload.clientPublicKey);
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    
    final dataToSign = utf8.encode(payload.getDataToSign());
    final signatureBytes = base64Decode(payload.clientSignature);
    final signature = Signature(signatureBytes, publicKey: publicKey);

    return await _algorithm.verify(
      dataToSign,
      signature: signature,
    );
  }
}
