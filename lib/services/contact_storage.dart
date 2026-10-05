
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';


class ContactStorage {
  static const _key = 'contacts_v1';

  Future<List<Contact>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data — start fresh instead of crashing.
      return [];
    }
  }

  Future<void> save(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
