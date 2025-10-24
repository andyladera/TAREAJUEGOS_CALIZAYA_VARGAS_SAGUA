import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Por defecto, mostramos la pantalla de login
  bool showLoginScreen = true;

  // Método para cambiar de pantalla
  void toggleScreens() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Si el usuario NO está logueado
        if (!snapshot.hasData) {
          if (showLoginScreen) {
            return LoginScreen(showRegisterScreen: toggleScreens);
          } else {
            return RegisterScreen(showLoginScreen: toggleScreens);
          }
        }

        // 2. Si el usuario SÍ está logueado
        return const HomeScreen(); // Lo mandamos al Home
      },
    );
  }
}