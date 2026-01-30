// =============================================================================
// splash_page.dart - PAGE : ÉCRAN DE DÉMARRAGE (SPLASH SCREEN)
// =============================================================================
// Premier écran affiché au lancement de l'application.
// Son rôle : afficher le logo pendant 2 secondes puis rediriger l'utilisateur
// vers la bonne page selon son état de connexion :
//   - Connecté -> HomePage (liste des utilisateurs)
//   - Non connecté -> LoginPage (formulaire de connexion)
//
// C'est une Vue (View) dans le pattern MVVM.
// Elle ne contient pas de logique métier, juste de l'affichage et de la navigation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import 'login_page.dart';
import 'home_page.dart';

/// Écran de démarrage de l'application (splash screen).
///
/// C'est un StatefulWidget car il a un comportement qui évolue dans le temps
/// (attente de 2 secondes puis navigation). Un StatelessWidget ne peut pas
/// déclencher d'action après le build initial.
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // initState() est appelé UNE SEULE FOIS quand le widget est créé.
    // On lance la redirection automatique dès que le splash s'affiche.
    _navigateToNextScreen();
  }

  /// Attend 2 secondes puis redirige vers la page appropriée.
  ///
  /// Vérifie l'état de connexion via Firebase Auth :
  /// - Si currentUser != null -> l'utilisateur est déjà connecté -> HomePage
  /// - Si currentUser == null -> pas de session active -> LoginPage
  ///
  /// Le "mounted" check évite les erreurs si l'utilisateur quitte l'app
  /// pendant le délai de 2 secondes.
  Future<void> _navigateToNextScreen() async {
    // Attendre 2 secondes pour afficher le splash screen
    await Future.delayed(AppConstants.splashDuration);

    // Vérifier que le widget est encore affiché (pas détruit entre-temps)
    if (!mounted) return;

    // Vérifier si un utilisateur est connecté via Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Utilisateur connecté -> naviguer vers la page d'accueil
      // pushReplacement remplace la page actuelle (on ne peut pas revenir au splash)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Pas d'utilisateur connecté -> naviguer vers la page de connexion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'écran de splash est simple : fond violet avec logo + spinner au centre
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de bulle de chat comme logo de l'application
            Icon(
              Icons.chat_bubble_rounded,
              size: 100,
              color: AppConstants.onPrimary,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Nom de l'application en grand
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: AppConstants.titleFontSize * 1.5, // Extra grand
                fontWeight: FontWeight.bold,
                color: AppConstants.onPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Indicateur de chargement circulaire (spinner)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
