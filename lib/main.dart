// =============================================================================
// main.dart - POINT D'ENTRÉE DE L'APPLICATION
// =============================================================================
// Ce fichier est le premier fichier exécuté au lancement de l'application.
// Il a 3 responsabilités :
//   1. Initialiser Firebase (backend cloud de Google)
//   2. Configurer les Providers (système de gestion d'état MVVM)
//   3. Définir le thème visuel et les routes de navigation
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/chat_user_viewmodel.dart';
import 'viewmodel/chat_viewmodel.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';

/// Point d'entrée de l'application Flutter.
/// La fonction main() est la première fonction appelée quand l'app démarre.
/// Elle est "async" car l'initialisation de Firebase est asynchrone (prend du temps).
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() est OBLIGATOIRE quand on fait
  // des opérations asynchrones avant runApp(). Cela initialise le moteur Flutter.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise la connexion Firebase avec les options spécifiques à la plateforme
  // (Android, iOS, Web...). Les options sont générées automatiquement par FlutterFire CLI.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lance l'application Flutter avec le widget racine MyApp
  runApp(const MyApp());
}

/// Widget racine de l'application.
/// C'est un StatelessWidget car sa configuration ne change pas après le build initial.
/// Il configure :
///   - Les Providers (injection de dépendances pour le pattern MVVM)
///   - Le thème Material Design 3
///   - Les routes de navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permet d'injecter PLUSIEURS ViewModels dans l'arbre de widgets.
    // Tous les widgets enfants pourront accéder à ces ViewModels via Provider.of()
    // ou Consumer<>. C'est le coeur du pattern MVVM avec Provider.
    return MultiProvider(
      providers: [
        // AuthViewModel : gère la connexion/inscription/déconnexion
        ChangeNotifierProvider(create: (_) => AuthViewModel()),

        // ChatUserViewModel : gère la liste des utilisateurs et les profils
        ChangeNotifierProvider(create: (_) => ChatUserViewModel()),

        // ChatViewModel : gère les conversations et les messages
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: MaterialApp(
        // Nom de l'app affiché dans le gestionnaire de tâches
        title: AppConstants.appName,

        // Supprime le bandeau "DEBUG" en haut à droite
        debugShowCheckedModeBanner: false,

        // Configuration du thème visuel Material Design 3
        theme: ThemeData(
          // Active Material Design 3 (le design system le plus récent de Google)
          useMaterial3: true,

          // Génère une palette de couleurs à partir d'une couleur de base (violet)
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            primary: AppConstants.primaryColor,
            secondary: AppConstants.secondaryColor,
            error: AppConstants.errorColor,
          ),

          // Couleur de fond par défaut de toutes les pages
          scaffoldBackgroundColor: AppConstants.backgroundColor,

          // Style par défaut de toutes les AppBar (barres en haut des pages)
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.onPrimary, // Couleur du texte/icônes
            elevation: 0, // Pas d'ombre sous la barre
          ),

          // Style par défaut de tous les champs de texte (TextFormField, TextField)
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            filled: true, // Fond rempli
            fillColor: AppConstants.surfaceColor, // Fond blanc
          ),

          // Style par défaut de tous les boutons ElevatedButton
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: AppConstants.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
                vertical: AppConstants.defaultPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
          ),
        ),

        // Page d'accueil au lancement = SplashPage (écran de chargement)
        home: const SplashPage(),

        // Définition des routes nommées pour la navigation
        // On peut naviguer vers ces pages avec Navigator.pushNamed('/login')
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
