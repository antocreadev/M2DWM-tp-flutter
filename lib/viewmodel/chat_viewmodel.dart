import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/chat.dart';
import '../model/message.dart';

/// ViewModel pour gérer les conversations et messages
class ChatViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Génère un ID de chat unique entre deux utilisateurs
  /// L'ID est toujours dans le même ordre (alphabétique) pour garantir l'unicité
  String _getChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  /// Crée ou récupère un chat existant entre deux utilisateurs
  Future<String?> getOrCreateChat(String otherUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final chatId = _getChatId(currentUserId, otherUserId);
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Créer un nouveau chat
        final chat = Chat(
          id: chatId,
          participants: [currentUserId, otherUserId],
        );

        await _firestore.collection('chats').doc(chatId).set(chat.toMap());
        debugPrint('✅ Nouveau chat créé: $chatId');
      }

      return chatId;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du chat: $e');
      _errorMessage = 'Impossible de créer la conversation';
      notifyListeners();
      return null;
    }
  }

  /// Envoie un message dans un chat
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final message = Message(
        from: currentUserId,
        to: receiverId,
        content: content,
        timestamp: DateTime.now(),
      );

      // Ajouter le message à Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Mettre à jour le lastMessage du chat
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ Message envoyé: $content');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message: $e');
      _errorMessage = 'Impossible d\'envoyer le message';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stream des messages d'un chat (triés par timestamp)
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
    });
  }

  /// Récupère la liste des chats de l'utilisateur
  Stream<List<Chat>> getUserChatsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
