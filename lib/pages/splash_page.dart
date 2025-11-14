import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import 'login_page.dart';
import 'home_page.dart';

/// Écran de démarrage de l'application
/// Affiche le logo et redirige vers la page appropriée
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  /// Attend 2 secondes puis redirige vers la page appropriée
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(AppConstants.splashDuration);

    if (!mounted) return;

    // Vérifie si un utilisateur est connecté
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Utilisateur connecté -> HomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Pas d'utilisateur -> LoginPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
            Icon(
              Icons.chat_bubble_rounded,
              size: 100,
              color: AppConstants.onPrimary,
            ),
            const SizedBox(height: AppConstants.largePadding),
            // Nom de l'application
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: AppConstants.titleFontSize * 1.5,
                fontWeight: FontWeight.bold,
                color: AppConstants.onPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            // Indicateur de chargement
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
