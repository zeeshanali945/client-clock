import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local-only storage. Everything stays on the device (offline-first).
class Storage {
  Storage(this._prefs);
  final SharedPreferences _prefs;

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  Profile? loadProfile() {
    final s = _prefs.getString('profile');
    if (s == null) return null;
    try {
      return Profile.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(Profile p) async {
    await _prefs.setString('profile', jsonEncode(p.toJson()));
  }

  List<Client> loadClients() {
    final s = _prefs.getString('clients');
    if (s == null) return [];
    try {
      final list = jsonDecode(s) as List;
      return list.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveClients(List<Client> clients) async {
    await _prefs.setString(
      'clients',
      jsonEncode(clients.map((c) => c.toJson()).toList()),
    );
  }
}
