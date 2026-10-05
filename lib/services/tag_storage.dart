
import 'package:shared_preferences/shared_preferences.dart';


class TagStorage {
  static const _key = 'tags_v1';

  /// Seeded the first time the app runs. After that, the persisted list
  /// is the source of truth.
  static const _defaults = <String>[
    'Family',
    'Friends',
    'Work',
    'School',
    'VIP',
  ];

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) {
      await prefs.setStringList(_key, _defaults);
      return List<String>.from(_defaults);
    }
    return List<String>.from(raw);
  }

  Future<void> save(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, tags);
  }
}
