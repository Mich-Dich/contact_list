
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/contact.dart';


class ExportService {
  /// Serializes the given contacts and copies a JSON document to the
  /// system clipboard. The shape is versioned so future importers can
  /// detect and adapt.
  static Future<void> exportToClipboard(List<Contact> contacts) async {
    final doc = {
      'app': 'contact_list',
      'version': 1,
      'exported': DateTime.now().toIso8601String(),
      'count': contacts.length,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    };

    final pretty = const JsonEncoder.withIndent('  ').convert(doc);
    await Clipboard.setData(ClipboardData(text: pretty));
  }
}
