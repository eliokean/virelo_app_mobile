import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveManager {
  static const String boxName = 'virelo_offline_box';
  static const String keyName = 'hive_aes_key';

  /// Initialise et ouvre de façon sécurisée la box Hive chiffrée
  static Future<Box> openOfflineBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    try {
      await Hive.initFlutter();
    } catch (_) {}

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: keyName);
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      encryptionKeyString = base64UrlEncode(key);
      await secureStorage.write(
        key: keyName,
        value: encryptionKeyString,
      );
    }

    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);
    return await Hive.openBox(
      boxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    );
  }
}
