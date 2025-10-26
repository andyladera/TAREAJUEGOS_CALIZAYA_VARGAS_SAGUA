import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart'; // Importamos nuestro controlador
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laberinto App',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          primary: Colors.deepPurple[300]!,
          secondary: Colors.tealAccent[200]!,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: Typography.material2021().white.copyWith(
              titleLarge: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              bodyMedium: const TextStyle(fontSize: 16),
            ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // Esta es la línea clave
    );
  }
}