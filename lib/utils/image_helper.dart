// =============================================================================
// image_helper.dart - UTILITAIRE : GESTION DES IMAGES
// =============================================================================
// Classe utilitaire avec des méthodes STATIQUES pour manipuler les images.
//
// Toutes les méthodes sont "static" = on les appelle directement sur la classe
// sans créer d'instance. Ex: ImageHelper.isValidBase64(myString)
//
// Les avatars sont stockés en BASE64 dans Firestore :
//   - Base64 = encodage qui convertit des données binaires (image) en texte
//   - Avantage : simple à stocker dans Firestore (qui ne gère que du texte/JSON)
//   - Inconvénient : la taille augmente de ~33% et est limitée
//
// Utilisé dans : ProfilePage (sélection avatar), HomePage et ChatPage (affichage)
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Classe utilitaire pour la gestion des images en base64.
///
/// Fournit des méthodes statiques pour :
/// - Convertir des images en base64 et vice-versa
/// - Valider des chaînes base64
/// - Compresser et vérifier la taille des images
class ImageHelper {
  /// Convertit un fichier image (XFile) en chaîne base64.
  ///
  /// XFile est le type retourné par ImagePicker quand l'utilisateur
  /// sélectionne une image. readAsBytes() lit le fichier en mémoire,
  /// puis base64Encode() convertit les bytes en texte.
  static Future<String> xFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Convertit une chaîne base64 en Uint8List (tableau de bytes) pour affichage.
  ///
  /// Uint8List est le format attendu par MemoryImage() pour créer un widget
  /// Image à partir de données en mémoire (et non un fichier ou une URL).
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

  /// Vérifie si une chaîne est un base64 valide.
  ///
  /// Tente de décoder la chaîne : si ça marche, c'est valide.
  /// Utilisé avant d'afficher un avatar pour éviter les crashs si les
  /// données sont corrompues ou vides.
  static bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }
    try {
      base64Decode(base64String); // Tente le décodage
      return true; // Pas d'erreur = valide
    } catch (e) {
      return false; // Erreur = invalide
    }
  }

  /// Compresse et convertit une image en base64 avec vérification de taille.
  ///
  /// Retourne la chaîne base64 si l'image est sous la limite de taille,
  /// ou null si l'image est trop grande.
  ///
  /// [maxSizeInBytes] : taille maximum en bytes (500KB par défaut = 500000)
  ///
  /// Note : la compression JPEG est déjà faite par ImagePicker (imageQuality: 85).
  /// Cette méthode vérifie juste que le résultat final ne dépasse pas la limite.
  static Future<String?> compressAndConvertToBase64(
    XFile file, {
    int maxSizeInBytes = 500000, // 500KB par défaut
  }) async {
    final bytes = await file.readAsBytes();

    // Vérifier que l'image ne dépasse pas la taille maximum
    if (bytes.length > maxSizeInBytes) {
      // L'image est trop grande -> retourne null (l'appelant affichera un message)
      return null;
    }

    // L'image est assez petite -> la convertir en base64
    return base64Encode(bytes);
  }

  /// Calcule la taille approximative en KB d'une chaîne base64.
  ///
  /// En base64, chaque 4 caractères représentent 3 bytes originaux.
  /// Donc la taille originale ≈ (longueur * 3) / 4
  /// On divise ensuite par 1024 pour obtenir des KB.
  static double getBase64SizeInKB(String base64String) {
    final sizeInBytes = (base64String.length * 3) / 4;
    return sizeInBytes / 1024;
  }
}
