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

  /// Contre-reçu marchand : le device marchand signe la preuve du client
  /// (sa chaîne canonique) liée à son identité et à l'instant d'encaissement.
  ///
  /// Doit rester identique à `CryptoLogic::buildMerchantReceiptToSign()` côté
  /// backend : `"MRCPT:<clientDataToSign>:<merchantId>:<merchantTimestamp>"`.
  /// Retourne `{ 'signature': base64, 'publicKey': base64 }`.
  Future<Map<String, String>> signMerchantReceipt({
    required String clientDataToSign,
    required String merchantId,
    required String merchantTimestamp,
  }) async {
    final keyPair = await _storageService.getKeyPair(_algorithm);
    if (keyPair == null) {
      throw Exception('Clés cryptographiques du marchand non initialisées');
    }
    final data = utf8.encode('MRCPT:$clientDataToSign:$merchantId:$merchantTimestamp');
    final signature = await _algorithm.sign(data, keyPair: keyPair);
    return {
      'signature': base64Encode(signature.bytes),
      'publicKey': await getPublicKey() ?? '',
    };
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
    final now = DateTime.now();
    final timestamp = now.toIso8601String();
    final validUntil = now.add(const Duration(seconds: 90)).toIso8601String();
    final publicKeyBase64 = await getPublicKey() ?? '';
    
    // Génère une référence lisible type VIR-OFF-XXXXX au lieu d'un long UUID
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomStr = String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(DateTime.now().microsecondsSinceEpoch % chars.length))); // Fallback basique
    final payloadUuid = 'VIR-OFF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}$randomStr';

    // On prépare le payload sans la signature
    final payloadWithoutSig = OfflineAuthorizationPayload(
      clientId: clientId,
      merchantId: merchantId,
      amount: amount,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      uuid: payloadUuid,
      clientPublicKey: publicKeyBase64,
      clientSignature: '', // Sera rempli juste après
      validUntil: validUntil,
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
      uuid: payloadUuid,
      clientPublicKey: publicKeyBase64,
      clientSignature: base64Encode(signature.bytes),
      validUntil: validUntil,
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

  /// Chiffrement symétrique pour protéger visuellement le QR Code ou le tag NFC (Privacy)
  /// Utilise une clé dérivée ou un master secret partagé (POC). 
  /// En production bancaire absolue, on utiliserait ECDH (X25519) avec la clé publique du marchand.
  Future<String> encryptPayload(OfflineAuthorizationPayload payload) async {
    final aesGcm = AesGcm.with256bits();
    final secretKey = await aesGcm.newSecretKeyFromBytes(
      utf8.encode('virelo_master_secret_key_32bytes') // À stocker sécuritairement
    );
    final nonce = aesGcm.newNonce();
    final clearText = utf8.encode(jsonEncode(payload.toJson()));

    final secretBox = await aesGcm.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
    );

    // On retourne le nonce concaténé au texte chiffré (format classique)
    final encryptedBytes = secretBox.concatenation();
    return base64Encode(encryptedBytes);
  }

  /// Déchiffrement du payload côté Marchand
  Future<OfflineAuthorizationPayload> decryptPayload(String encryptedBase64) async {
    final encryptedBytes = base64Decode(encryptedBase64);
    final aesGcm = AesGcm.with256bits();
    final secretKey = await aesGcm.newSecretKeyFromBytes(
      utf8.encode('virelo_master_secret_key_32bytes')
    );

    final secretBox = SecretBox.fromConcatenation(
      encryptedBytes, 
      nonceLength: aesGcm.nonceLength, 
      macLength: aesGcm.macAlgorithm.macLength
    );

    final clearText = await aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    final jsonString = utf8.decode(clearText);
    return OfflineAuthorizationPayload.fromJson(jsonDecode(jsonString));
  }
}
