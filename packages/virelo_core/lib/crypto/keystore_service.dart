import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class KeyStoreService {
  final FlutterSecureStorage _secureStorage;

  static const String _privateKeyName = 'virelo_private_key';
  static const String _publicKeyName = 'virelo_public_key';

  KeyStoreService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Génère une paire de clés Ed25519 et les sauvegarde dans le Secure Storage
  Future<void> generateAndStoreKeys() async {
    final keyPair = ed.generateKey();
    
    // Convert to base64 for easy storage
    final privateKeyBase64 = base64Encode(keyPair.privateKey.bytes);
    final publicKeyBase64 = base64Encode(keyPair.publicKey.bytes);

    await _secureStorage.write(
      key: _privateKeyName,
      value: privateKeyBase64,
      iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );

    await _secureStorage.write(
      key: _publicKeyName,
      value: publicKeyBase64,
      iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  /// Retourne la clé publique en base64
  Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: _publicKeyName);
  }

  /// Signe une donnée (ex: le token JWT) avec la clé privée protégée
  Future<String> signData(String data) async {
    final privateKeyBase64 = await _secureStorage.read(key: _privateKeyName);
    if (privateKeyBase64 == null) {
      throw Exception('Private key not found in KeyStore. Please generate keys first.');
    }

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final privateKey = ed.PrivateKey(privateKeyBytes);

    final dataBytes = utf8.encode(data);
    final signatureBytes = ed.sign(privateKey, dataBytes);

    return base64Encode(signatureBytes);
  }

  /// Révoque les clés (ex: suppression du compte ou déconnexion totale)
  Future<void> revokeKeys() async {
    await _secureStorage.delete(key: _privateKeyName);
    await _secureStorage.delete(key: _publicKeyName);
  }
}
