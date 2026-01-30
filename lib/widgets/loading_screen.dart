// =============================================================================
// loading_screen.dart - WIDGET RÉUTILISABLE : ÉCRAN DE CHARGEMENT
// =============================================================================
// Widget générique qui affiche un spinner centré avec un message optionnel.
// Peut être utilisé comme écran plein pour les transitions ou les chargements
// longs.
//
// C'est un widget RÉUTILISABLE : il peut être utilisé dans n'importe quelle
// page de l'application quand on a besoin d'afficher un état de chargement.
//
// Note : dans l'implémentation actuelle, ce widget n'est pas directement
// utilisé dans les pages (qui utilisent des CircularProgressIndicator inline),
// mais il est disponible pour une utilisation future.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:chat_app/constants.dart';

/// Widget d'écran de chargement plein écran avec spinner et message optionnel.
///
/// Utilisation :
/// ```dart
/// // Sans message
/// LoadingScreen()
///
/// // Avec message
/// LoadingScreen(message: "Chargement des messages...")
/// ```
class LoadingScreen extends StatelessWidget {
  /// Message optionnel affiché sous le spinner
  /// Si null, seul le spinner est affiché
  final String? message;

  const LoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner circulaire avec la couleur primaire
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppConstants.primaryColor,
              ),
            ),
            // Affiche le message seulement s'il est fourni
            // L'opérateur ... (spread) insère conditionnellement les widgets
            if (message != null) ...[
              const SizedBox(height: AppConstants.largePadding),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: AppConstants.bodyFontSize,
                  color: AppConstants.onBackground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
