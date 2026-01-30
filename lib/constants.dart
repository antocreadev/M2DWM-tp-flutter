// =============================================================================
// constants.dart - CONSTANTES GLOBALES DE L'APPLICATION
// =============================================================================
// Ce fichier centralise TOUTES les valeurs constantes de l'application :
//   - Couleurs du thème
//   - Dimensions (padding, border radius, tailles de police)
//   - Textes de l'interface (labels, boutons, messages d'erreur)
//   - Durées d'animation
//
// POURQUOI ? Centraliser les constantes permet de :
//   - Modifier le thème en un seul endroit (ex: changer la couleur primaire)
//   - Assurer la cohérence visuelle dans toute l'app
//   - Faciliter la traduction (tous les textes sont ici)
//   - Éviter les "magic numbers" (valeurs codées en dur sans explication)
// =============================================================================

import 'package:flutter/material.dart';

/// Classe regroupant toutes les constantes de l'application Chat App.
/// Toutes les propriétés sont "static const" = accessibles sans instancier la classe.
/// Exemple d'utilisation : AppConstants.primaryColor
class AppConstants {
  // ---------------------------------------------------------------------------
  // COULEURS PRINCIPALES (palette Material Design)
  // ---------------------------------------------------------------------------

  /// Couleur primaire de l'app (violet foncé) - utilisée pour les AppBar, boutons
  static const Color primaryColor = Color(0xFF6200EA);

  /// Variante claire du violet - utilisée pour les éléments secondaires
  static const Color primaryLight = Color(0xFFBB86FC);

  /// Variante foncée du violet - utilisée pour les éléments de contraste
  static const Color primaryDark = Color(0xFF3700B3);

  /// Couleur secondaire (turquoise) - utilisée pour les accents visuels
  static const Color secondaryColor = Color(0xFF03DAC6);

  /// Couleur d'erreur (rouge rosé) - utilisée pour les messages d'erreur
  static const Color errorColor = Color(0xFFCF6679);

  /// Couleur de fond des pages (gris très clair)
  static const Color backgroundColor = Color(0xFFF5F5F5);

  /// Couleur de surface (blanc) - utilisée pour les cartes et champs de texte
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Couleur du texte/icônes SUR la couleur primaire (blanc)
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Couleur du texte SUR le fond (noir)
  static const Color onBackground = Color(0xFF000000);

  /// Couleur du texte SUR les surfaces (noir)
  static const Color onSurface = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // COULEURS DES BULLES DE MESSAGES
  // ---------------------------------------------------------------------------

  /// Couleur de fond de MES messages (violet = couleur primaire)
  static const Color myMessageColor = Color(0xFF6200EA);

  /// Couleur de fond des messages des AUTRES (gris clair)
  static const Color otherMessageColor = Color(0xFFE0E0E0);

  /// Couleur du texte de MES messages (blanc sur fond violet)
  static const Color myMessageTextColor = Colors.white;

  /// Couleur du texte des messages des AUTRES (noir sur fond gris)
  static const Color otherMessageTextColor = Colors.black87;

  // ---------------------------------------------------------------------------
  // DIMENSIONS (en pixels logiques)
  // ---------------------------------------------------------------------------

  /// Padding standard utilisé entre les éléments (16px)
  static const double defaultPadding = 16.0;

  /// Petit padding pour les espaces réduits (8px)
  static const double smallPadding = 8.0;

  /// Grand padding pour les marges importantes (24px)
  static const double largePadding = 24.0;

  /// Rayon de courbure des coins arrondis (12px)
  static const double borderRadius = 12.0;

  /// Rayon des petits avatars dans les listes (25px)
  static const double avatarRadius = 25.0;

  /// Rayon du grand avatar sur la page profil (50px)
  static const double largeAvatarRadius = 50.0;

  // ---------------------------------------------------------------------------
  // TAILLES DE POLICE
  // ---------------------------------------------------------------------------

  /// Taille des titres principaux (24px)
  static const double titleFontSize = 24.0;

  /// Taille des sous-titres (16px)
  static const double subtitleFontSize = 16.0;

  /// Taille du texte courant (14px)
  static const double bodyFontSize = 14.0;

  /// Taille des légendes et horodatages (12px)
  static const double captionFontSize = 12.0;

  // ---------------------------------------------------------------------------
  // TEXTES DE L'INTERFACE UTILISATEUR
  // ---------------------------------------------------------------------------

  /// Nom de l'application
  static const String appName = 'Chat App';

  /// Titres des pages
  static const String loginTitle = 'Connexion';
  static const String signupTitle = 'Inscription';

  /// Labels des champs de formulaire
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Mot de passe';
  static const String displayNameLabel = 'Nom complet';
  static const String bioLabel = 'Bio';

  /// Textes des boutons
  static const String loginButton = 'Se connecter';
  static const String signupButton = 'S\'inscrire';
  static const String updateProfile = 'Mettre à jour le profil';
  static const String changeAvatar = 'Changer l\'avatar';

  /// Textes de navigation entre pages
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas de compte ?';
  static const String hasAccount = 'Déjà un compte ?';

  /// Textes divers
  static const String logout = 'Déconnexion';
  static const String profile = 'Profil';
  static const String typeMessage = 'Tapez un message...';
  static const String noUsers = 'Aucun utilisateur disponible';
  static const String loading = 'Chargement...';
  static const String error = 'Erreur';

  // ---------------------------------------------------------------------------
  // MESSAGES D'ERREUR DE VALIDATION
  // ---------------------------------------------------------------------------

  /// Erreurs de validation du formulaire
  static const String emailRequired = 'L\'email est requis';
  static const String emailInvalid = 'Email invalide';
  static const String passwordRequired = 'Le mot de passe est requis';
  static const String passwordTooShort =
      'Le mot de passe doit contenir au moins 6 caractères';
  static const String displayNameRequired = 'Le nom est requis';

  /// Erreurs réseau/Firebase
  static const String loginError = 'Erreur de connexion';
  static const String signupError = 'Erreur lors de l\'inscription';
  static const String updateProfileError =
      'Erreur lors de la mise à jour du profil';
  static const String sendMessageError = 'Erreur lors de l\'envoi du message';

  // ---------------------------------------------------------------------------
  // DURÉES
  // ---------------------------------------------------------------------------

  /// Durée d'affichage du splash screen au démarrage (2 secondes)
  static const Duration splashDuration = Duration(seconds: 2);

  /// Durée d'affichage des snackbars (messages temporaires en bas de l'écran)
  static const Duration snackbarDuration = Duration(seconds: 3);
}
