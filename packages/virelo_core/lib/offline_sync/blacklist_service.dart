import 'package:hive/hive.dart';

class BlacklistService {
  static const String _boxName = 'virelo_blacklist';
  late Box<String> _blacklistBox;

  Future<void> init() async {
    _blacklistBox = await Hive.openBox<String>(_boxName);
  }

  /// Met à jour la liste noire locale à partir des données reçues du backend
  Future<void> updateBlacklist(List<String> bannedUserIds) async {
    await _blacklistBox.clear();
    for (var userId in bannedUserIds) {
      await _blacklistBox.put(userId, userId);
    }
  }

  /// Vérifie si un utilisateur est dans la liste noire
  bool isUserBanned(String userId) {
    return _blacklistBox.containsKey(userId);
  }

  /// Vider la liste noire (ex: lors d'une déconnexion)
  Future<void> clearBlacklist() async {
    await _blacklistBox.clear();
  }
}
