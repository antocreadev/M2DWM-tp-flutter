import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Classe utilitaire pour gérer les images en base64
class ImageHelper {
  /// Convertit un fichier XFile en chaîne base64
  static Future<String> xFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Convertit une chaîne base64 en Uint8List pour affichage
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

  /// Vérifie si une chaîne base64 est valide
  static bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Compresse et convertit une image en base64 (limite la taille)
  /// Retourne null si l'image est trop grande après compression
  static Future<String?> compressAndConvertToBase64(
    XFile file, {
    int maxSizeInBytes = 500000, // 500KB par défaut
  }) async {
    final bytes = await file.readAsBytes();

    // Vérifier la taille
    if (bytes.length > maxSizeInBytes) {
      // TODO: Implémenter une compression d'image si nécessaire
      // Pour l'instant, on refuse les images trop grandes
      return null;
    }

    return base64Encode(bytes);
  }

  /// Calcule la taille approximative en KB d'une chaîne base64
  static double getBase64SizeInKB(String base64String) {
    // La taille base64 est environ 4/3 de la taille originale
    final sizeInBytes = (base64String.length * 3) / 4;
    return sizeInBytes / 1024;
  }
}
