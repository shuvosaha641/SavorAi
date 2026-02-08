import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeappflutter/services/auth_service.dart';
import 'package:recipeappflutter/pages/login.dart';
import 'package:recipeappflutter/pages/home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateStream,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return const Home();
        }

        // User is not authenticated
        return const LoginPage();
      },
    );
  }
}
