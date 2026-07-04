import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virelo_core/services/auth_service.dart';

class OfflineStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService;

  static const String _keyPrivateKey = 'offline_private_key';
  static const String _keyPublicKey = 'offline_public_key';
  static const String _keySequenceNumber = 'offline_sequence_number';

  OfflineStorageService(this._authService);

  // --- Gestion du Nonce (Sequence Number) ---
  
  Future<int> getCurrentSequenceNumber() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");
    
    final key = '${_keySequenceNumber}_$userId';
    final val = await _secureStorage.read(key: key);
    if (val == null) return 0;
    return int.tryParse(val) ?? 0;
  }

  Future<int> incrementAndGetSequenceNumber() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");
    
    final current = await getCurrentSequenceNumber();
    final next = current + 1;
    final key = '${_keySequenceNumber}_$userId';
    await _secureStorage.write(key: key, value: next.toString());
    return next;
  }

  // --- Gestion des clés cryptographiques ---

  Future<void> saveKeyPair(SimpleKeyPair keyPair) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    await _secureStorage.write(
      key: '${_keyPrivateKey}_$userId',
      value: base64Encode(privateKeyBytes),
    );
    await _secureStorage.write(
      key: '${_keyPublicKey}_$userId',
      value: base64Encode(publicKeyBytes),
    );
  }

  Future<SimpleKeyPair?> getKeyPair(Ed25519 algorithm) async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;

    final privateKeyStr = await _secureStorage.read(key: '${_keyPrivateKey}_$userId');
    final publicKeyStr = await _secureStorage.read(key: '${_keyPublicKey}_$userId');

    if (privateKeyStr == null || publicKeyStr == null) return null;

    final privateKeyBytes = base64Decode(privateKeyStr);
    final publicKeyBytes = base64Decode(publicKeyStr);

    return SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }

  Future<String?> getPublicKeyBase64() async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;
    return await _secureStorage.read(key: '${_keyPublicKey}_$userId');
  }
}
