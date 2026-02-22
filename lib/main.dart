import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'debug/test_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test de diagnostic des données
  await testTollData();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecotoroute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
