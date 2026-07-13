import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:virelo_core/services/auth_service.dart';

class OfflineStorageService {
  Box get _box => Hive.box('virelo_offline_box');
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
    final val = _box.get(key);
    if (val == null) return 0;
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<int> incrementAndGetSequenceNumber() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");
    
    final current = await getCurrentSequenceNumber();
    final next = current + 1;
    final key = '${_keySequenceNumber}_$userId';
    await _box.put(key, next.toString());
    return next;
  }

  // --- Gestion des clés cryptographiques ---

  Future<void> saveKeyPair(SimpleKeyPair keyPair) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    await _box.put('${_keyPrivateKey}_$userId', base64Encode(privateKeyBytes));
    await _box.put('${_keyPublicKey}_$userId', base64Encode(publicKeyBytes));
  }

  Future<SimpleKeyPair?> getKeyPair(Ed25519 algorithm) async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;

    final privateKeyStr = _box.get('${_keyPrivateKey}_$userId');
    final publicKeyStr = _box.get('${_keyPublicKey}_$userId');

    if (privateKeyStr == null || publicKeyStr == null) return null;

    final privateKeyBytes = base64Decode(privateKeyStr.toString());
    final publicKeyBytes = base64Decode(publicKeyStr.toString());

    return SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }

  Future<String?> getPublicKeyBase64() async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;
    return _box.get('${_keyPublicKey}_$userId')?.toString();
  }

  // --- Gestion du Solde Hors Ligne (Côté Client) ---

  Future<void> saveOfflineBudget(double amount) async {
    final userId = await _authService.getUserId();
    debugPrint('==== SAVING OFFLINE BUDGET: userId=$userId, amount=$amount ====');
    if (userId == null) return;
    await _box.put('offline_budget_$userId', amount.toString());
  }

  Future<double> getOfflineBudget() async {
    final userId = await _authService.getUserId();
    debugPrint('==== GETTING OFFLINE BUDGET: userId=$userId ====');
    if (userId == null) return 0.0;
    final val = _box.get('offline_budget_$userId');
    debugPrint('==== OFFLINE BUDGET RAW VALUE: $val ====');
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> deductOfflineBudget(double amount) async {
    final current = await getOfflineBudget();
    if (current >= amount) {
      await saveOfflineBudget(current - amount);
    } else {
      throw Exception('Solde hors ligne insuffisant');
    }
  }

  // --- Gestion de l'historique local ---

  Future<void> saveOfflineTransaction(Map<String, dynamic> transaction) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    
    final key = 'offline_history_$userId';
    final currentHistoryStr = _box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(currentHistoryStr.toString());
    
    // Ajoute la date courante si non présente
    transaction['date'] = DateTime.now().toIso8601String();
    
    history.add(transaction);
    await _box.put(key, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getOfflineTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];
    
    final key = 'offline_history_$userId';
    final historyStr = _box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr.toString());
    
    return history.map((e) => e as Map<String, dynamic>).toList().reversed.toList();
  }

  Future<void> removeOfflineTransaction(String uuid) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    
    final key = 'offline_history_$userId';
    final historyStr = _box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr.toString());
    
    final updatedHistory = history.where((e) => (e as Map)['uuid'] != uuid).toList();
    await _box.put(key, jsonEncode(updatedHistory));
  }

  Future<void> clearOfflineTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    await _box.delete('offline_history_$userId');
  }
}
