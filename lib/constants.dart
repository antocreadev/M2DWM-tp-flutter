import 'package:flutter/material.dart';

/// Constantes de l'application Chat App
class AppConstants {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF6200EA);
  static const Color primaryLight = Color(0xFFBB86FC);
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);

  // Couleurs pour les messages
  static const Color myMessageColor = Color(0xFF6200EA);
  static const Color otherMessageColor = Color(0xFFE0E0E0);
  static const Color myMessageTextColor = Colors.white;
  static const Color otherMessageTextColor = Colors.black87;

  // Tailles
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double avatarRadius = 25.0;
  static const double largeAvatarRadius = 50.0;

  // Tailles de police
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;

  // Textes
  static const String appName = 'Chat App';
  static const String loginTitle = 'Connexion';
  static const String signupTitle = 'Inscription';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Mot de passe';
  static const String displayNameLabel = 'Nom complet';
  static const String loginButton = 'Se connecter';
  static const String signupButton = 'S\'inscrire';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas de compte ?';
  static const String hasAccount = 'Déjà un compte ?';
  static const String logout = 'Déconnexion';
  static const String profile = 'Profil';
  static const String bioLabel = 'Bio';
  static const String updateProfile = 'Mettre à jour le profil';
  static const String changeAvatar = 'Changer l\'avatar';
  static const String typeMessage = 'Tapez un message...';
  static const String noUsers = 'Aucun utilisateur disponible';
  static const String loading = 'Chargement...';
  static const String error = 'Erreur';

  // Messages d'erreur
  static const String emailRequired = 'L\'email est requis';
  static const String emailInvalid = 'Email invalide';
  static const String passwordRequired = 'Le mot de passe est requis';
  static const String passwordTooShort =
      'Le mot de passe doit contenir au moins 6 caractères';
  static const String displayNameRequired = 'Le nom est requis';
  static const String loginError = 'Erreur de connexion';
  static const String signupError = 'Erreur lors de l\'inscription';
  static const String updateProfileError =
      'Erreur lors de la mise à jour du profil';
  static const String sendMessageError = 'Erreur lors de l\'envoi du message';

  // Durées
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackbarDuration = Duration(seconds: 3);
}
