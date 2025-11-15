import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/chat_user.dart';

/// ViewModel pour gérer la liste des utilisateurs
class ChatUserViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream des utilisateurs (exclut l'utilisateur connecté)
  Stream<List<ChatUser>> getUsersStream() {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return Stream.value([]);
    }

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatUser.fromMap(doc.data()))
          .where((user) => user.id != currentUid)
          .toList();
    });
  }

  /// Récupère un utilisateur par son ID
  Future<ChatUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return ChatUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Met à jour le profil de l'utilisateur connecté
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? avatarBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) {
        throw Exception('Utilisateur non connecté');
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarBase64 != null) updates['avatarBase64'] = avatarBase64;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(currentUid).update(updates);

      debugPrint('✅ Profil mis à jour avec succès');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du profil: $e');
      _errorMessage = 'Impossible de mettre à jour le profil';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère l'utilisateur connecté
  Future<ChatUser?> getCurrentUser() async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return null;
    return getUserById(currentUid);
  }
}
