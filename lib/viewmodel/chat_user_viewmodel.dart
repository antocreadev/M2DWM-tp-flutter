// =============================================================================
// chat_user_viewmodel.dart - VIEWMODEL : GESTION DES UTILISATEURS
// =============================================================================
// Ce fichier gère la logique liée aux profils utilisateurs :
//   - Récupérer la liste de tous les utilisateurs (sauf soi-même)
//   - Récupérer un utilisateur par son ID
//   - Mettre à jour le profil (nom, bio, avatar)
//
// Il communique avec la collection Firestore "users" et expose des données
// réactives aux pages via ChangeNotifier + Provider.
//
// Utilisé dans : HomePage (liste des utilisateurs), ProfilePage (édition),
//                ChatPage (infos de l'interlocuteur)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/chat_user.dart';

/// ViewModel pour gérer la liste des utilisateurs et les opérations de profil.
///
/// Ce ViewModel expose des Streams (flux de données en temps réel) pour
/// que l'UI se mette à jour automatiquement quand un utilisateur change
/// son profil ou quand un nouvel utilisateur s'inscrit.
class ChatUserViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // INSTANCES FIREBASE
  // ---------------------------------------------------------------------------

  /// Firestore : pour lire/écrire dans la collection "users"
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase Auth : pour connaître l'utilisateur actuellement connecté
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // ÉTAT INTERNE
  // ---------------------------------------------------------------------------

  /// Liste des utilisateurs en cache (pour accès rapide)
  List<ChatUser> _users = [];

  /// Indicateur de chargement
  bool _isLoading = false;

  /// Message d'erreur (null = pas d'erreur)
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  /// Liste des utilisateurs en cache
  List<ChatUser> get users => _users;

  /// True si une opération est en cours
  bool get isLoading => _isLoading;

  /// Message d'erreur actuel
  String? get errorMessage => _errorMessage;

  /// UID de l'utilisateur actuellement connecté (raccourci pratique)
  String? get currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // MÉTHODES PUBLIQUES
  // ---------------------------------------------------------------------------

  /// Retourne un Stream (flux temps réel) de la liste des utilisateurs.
  ///
  /// Un Stream est comme un "tuyau" qui envoie des données en continu.
  /// À chaque fois qu'un utilisateur est ajouté/modifié/supprimé dans Firestore,
  /// le Stream émet automatiquement la nouvelle liste.
  ///
  /// IMPORTANT : L'utilisateur connecté est EXCLU de la liste (on ne peut pas
  /// s'envoyer des messages à soi-même).
  ///
  /// Utilisé dans HomePage avec StreamBuilder pour afficher la liste en temps réel.
  Stream<List<ChatUser>> getUsersStream() {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      // Si personne n'est connecté, retourne un Stream vide
      return Stream.value([]);
    }

    // .snapshots() retourne un Stream de QuerySnapshot (données temps réel Firestore)
    // .map() transforme chaque snapshot en liste de ChatUser
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatUser.fromMap(doc.data())) // Map -> ChatUser
          .where((user) => user.id != currentUid) // Exclure soi-même
          .toList();
    });
  }

  /// Récupère un utilisateur spécifique par son UID.
  ///
  /// Contrairement à getUsersStream(), cette méthode fait une lecture UNIQUE
  /// (pas de temps réel). Utilisée pour charger le profil d'un interlocuteur.
  ///
  /// Retourne null si l'utilisateur n'existe pas ou en cas d'erreur.
  Future<ChatUser?> getUserById(String userId) async {
    try {
      // .get() fait une lecture ponctuelle du document
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return ChatUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Met à jour le profil de l'utilisateur actuellement connecté dans Firestore.
  ///
  /// Seuls les champs non-null sont mis à jour (mise à jour partielle).
  /// Par exemple, si on passe uniquement bio: "Nouvelle bio", seul le champ
  /// bio est modifié, les autres restent inchangés.
  ///
  /// Ajoute aussi un champ 'updatedAt' avec le timestamp serveur pour tracer
  /// la dernière modification.
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Informe l'UI que le chargement commence

    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Construire le Map des champs à mettre à jour
      // On n'ajoute que les champs non-null pour faire une mise à jour partielle
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarBase64 != null) updates['avatarBase64'] = avatarBase64;
      // FieldValue.serverTimestamp() = le serveur Firebase génère le timestamp
      // (plus fiable que DateTime.now() car c'est l'heure du serveur)
      updates['updatedAt'] = FieldValue.serverTimestamp();

      // .update() modifie UNIQUEMENT les champs spécifiés (pas le document entier)
      await _firestore.collection('users').doc(currentUid).update(updates);

      debugPrint('Profil mis à jour avec succès');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      _errorMessage = 'Impossible de mettre à jour le profil';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère le profil de l'utilisateur actuellement connecté.
  /// C'est un raccourci qui combine currentUserId + getUserById.
  Future<ChatUser?> getCurrentUser() async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return null;
    return getUserById(currentUid);
  }
}
