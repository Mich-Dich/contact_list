
import 'package:flutter/material.dart';

import 'screens/contact_list_screen.dart';
import 'theme.dart';


void main() => runApp(const ContactApp());

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'contacts',
      debugShowCheckedModeBanner: false,
      theme: buildTerminalTheme(),
      home: const ContactListScreen(),
    );
  }
}
