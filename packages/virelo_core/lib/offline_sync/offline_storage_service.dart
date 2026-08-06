import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:virelo_core/services/auth_service.dart';
import 'hive_manager.dart';

class OfflineStorageService {
  Future<Box> _getBox() async => await HiveManager.openOfflineBox();
  final AuthService _authService;

  static const String _keyPrivateKey = 'offline_private_key';
  static const String _keyPublicKey = 'offline_public_key';
  static const String _keySequenceNumber = 'offline_sequence_number';

  OfflineStorageService(this._authService);

  // --- Gestion du Nonce (Sequence Number) ---
  
  Future<int> getCurrentSequenceNumber() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");
    
    final box = await _getBox();
    final key = '${_keySequenceNumber}_$userId';
    final val = box.get(key);
    if (val == null) return 0;
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<int> incrementAndGetSequenceNumber() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");
    
    final current = await getCurrentSequenceNumber();
    final next = current + 1;
    final box = await _getBox();
    final key = '${_keySequenceNumber}_$userId';
    await box.put(key, next.toString());
    return next;
  }

  // --- Gestion des clés cryptographiques ---

  Future<void> saveKeyPair(SimpleKeyPair keyPair) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception("Utilisateur non authentifié");

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    final box = await _getBox();
    await box.put('${_keyPrivateKey}_$userId', base64Encode(privateKeyBytes));
    await box.put('${_keyPublicKey}_$userId', base64Encode(publicKeyBytes));
  }

  Future<SimpleKeyPair?> getKeyPair(Ed25519 algorithm) async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;

    final box = await _getBox();
    final privateKeyStr = box.get('${_keyPrivateKey}_$userId');
    final publicKeyStr = box.get('${_keyPublicKey}_$userId');

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
    final box = await _getBox();
    return box.get('${_keyPublicKey}_$userId')?.toString();
  }

  // --- Gestion du Solde Hors Ligne (Côté Client) ---

  Future<void> saveOfflineBudget(double amount) async {
    final userId = await _authService.getUserId();
    debugPrint('==== SAVING OFFLINE BUDGET: userId=$userId, amount=$amount ====');
    if (userId == null) return;
    final box = await _getBox();
    await box.put('offline_budget_$userId', amount.toString());
  }

  Future<double> getOfflineBudget() async {
    final userId = await _authService.getUserId();
    debugPrint('==== GETTING OFFLINE BUDGET: userId=$userId ====');
    if (userId == null) return 0.0;
    final box = await _getBox();
    final val = box.get('offline_budget_$userId');
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
    
    final box = await _getBox();
    final key = 'offline_history_$userId';
    final currentHistoryStr = box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(currentHistoryStr.toString());
    
    // Ajoute la date courante si non présente
    transaction['date'] = DateTime.now().toIso8601String();
    
    history.add(transaction);
    await box.put(key, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getOfflineTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];
    
    final box = await _getBox();
    final key = 'offline_history_$userId';
    final historyStr = box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr.toString());
    
    return history.map((e) => e as Map<String, dynamic>).toList().reversed.toList();
  }

  Future<void> removeOfflineTransaction(String uuid) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    
    final box = await _getBox();
    final key = 'offline_history_$userId';
    final historyStr = box.get(key) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr.toString());
    
    final updatedHistory = history.where((e) => (e as Map)['uuid'] != uuid).toList();
    await box.put(key, jsonEncode(updatedHistory));
  }

  Future<void> clearOfflineTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    final box = await _getBox();
    await box.delete('offline_history_$userId');
  }

  // --- Gestion du Cache de l'Historique Global (Mode Hors-ligne) ---

  Future<void> saveCachedServerTransactions(List<dynamic> transactions) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;
    final box = await _getBox();
    await box.put('cached_server_history_$userId', jsonEncode(transactions));
  }

  Future<List<dynamic>> getCachedServerTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];
    final box = await _getBox();
    final dataStr = box.get('cached_server_history_$userId');
    if (dataStr == null) return [];
    try {
      final List<dynamic> data = jsonDecode(dataStr.toString());
      return data;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getFullCachedHistory() async {
    final offlineTx = await getOfflineTransactions();
    final serverTx = await getCachedServerTransactions();

    final List<dynamic> combined = [];
    final Set<String> seenIds = {};

    for (final tx in [...offlineTx, ...serverTx]) {
      final id = (tx['id'] ?? tx['uuid'] ?? tx['local_uuid'])?.toString();
      if (id != null && seenIds.contains(id)) continue;
      if (id != null) seenIds.add(id);
      combined.add(tx);
    }

    return combined;
  }
}

