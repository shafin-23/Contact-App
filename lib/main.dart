import 'package:flutter/material.dart';
import 'screens/contact_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContactApp());
}

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contact Manager',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor:
        const Color(0xFFF8F7FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7FC),
          elevation: 0,
          centerTitle: false,
        ),
      ),

      home: const ContactListScreen(),
    );
  }
}