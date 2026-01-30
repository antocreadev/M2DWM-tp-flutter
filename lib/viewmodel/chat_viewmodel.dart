// =============================================================================
// chat_viewmodel.dart - VIEWMODEL : GESTION DES CONVERSATIONS ET MESSAGES
// =============================================================================
// Ce fichier gère toute la logique des conversations et des messages :
//   - Créer ou récupérer une conversation entre deux utilisateurs
//   - Envoyer un message
//   - Écouter les messages en temps réel (Stream)
//   - Récupérer la liste des conversations de l'utilisateur
//
// Structure Firestore utilisée :
//   chats/                          <- Collection principale
//     {userId1}_{userId2}/          <- Document de conversation
//       participants: [uid1, uid2]
//       lastMessage: "..."
//       lastMessageTime: 123456789
//       messages/                   <- Sous-collection de messages
//         {autoId}/                 <- Document message
//           from: "uid1"
//           to: "uid2"
//           content: "Bonjour !"
//           timestamp: 123456789
//
// Utilisé dans : ChatPage (envoi/réception de messages)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/chat.dart';
import '../model/message.dart';

/// ViewModel pour gérer les conversations et les messages en temps réel.
///
/// Le chat entre deux utilisateurs est identifié par un ID unique formé
/// de leurs deux UIDs triés alphabétiquement, séparés par un underscore.
/// Cela garantit qu'il n'y a qu'UNE SEULE conversation entre deux personnes.
class ChatViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // INSTANCES FIREBASE
  // ---------------------------------------------------------------------------

  /// Firestore : pour lire/écrire dans les collections "chats" et "messages"
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase Auth : pour connaître l'expéditeur des messages
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // ÉTAT INTERNE
  // ---------------------------------------------------------------------------

  /// Indicateur de chargement (pendant l'envoi d'un message)
  bool _isLoading = false;

  /// Message d'erreur (null = pas d'erreur)
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // MÉTHODES PRIVÉES
  // ---------------------------------------------------------------------------

  /// Génère un ID de chat unique et DÉTERMINISTE entre deux utilisateurs.
  ///
  /// Les deux UIDs sont triés par ordre alphabétique puis concaténés avec "_".
  /// Exemple : _getChatId("xyz", "abc") = "abc_xyz"
  /// Exemple : _getChatId("abc", "xyz") = "abc_xyz"
  ///
  /// Le tri alphabétique garantit que le MÊME ID est généré peu importe
  /// quel utilisateur initie la conversation.
  String _getChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort(); // Tri alphabétique
    return '${users[0]}_${users[1]}';
  }

  // ---------------------------------------------------------------------------
  // MÉTHODES PUBLIQUES
  // ---------------------------------------------------------------------------

  /// Crée une nouvelle conversation ou récupère une conversation existante.
  ///
  /// Vérifie d'abord si le document chat existe dans Firestore.
  /// Si non, crée un nouveau document avec les deux participants.
  /// Retourne l'ID du chat (ou null en cas d'erreur).
  ///
  /// Appelé au début de ChatPage pour initialiser la conversation.
  Future<String?> getOrCreateChat(String otherUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Générer l'ID unique de la conversation
      final chatId = _getChatId(currentUserId, otherUserId);

      // Vérifier si la conversation existe déjà
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // La conversation n'existe pas -> en créer une nouvelle
        final chat = Chat(
          id: chatId,
          participants: [currentUserId, otherUserId],
        );

        // Écrire le nouveau document dans Firestore
        await _firestore.collection('chats').doc(chatId).set(chat.toMap());
        debugPrint('Nouveau chat créé: $chatId');
      }

      return chatId;
    } catch (e) {
      debugPrint('Erreur lors de la création du chat: $e');
      _errorMessage = 'Impossible de créer la conversation';
      notifyListeners();
      return null;
    }
  }

  /// Envoie un message dans une conversation.
  ///
  /// Étapes :
  /// 1. Crée un objet Message avec l'expéditeur, le destinataire et le contenu
  /// 2. Ajoute le message dans la sous-collection "messages" du chat
  /// 3. Met à jour le document chat avec le dernier message (pour l'aperçu)
  ///
  /// Le message apparaît instantanément chez les deux utilisateurs grâce
  /// aux Streams Firestore (temps réel).
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

      // ÉTAPE 1 : Créer l'objet Message
      final message = Message(
        from: currentUserId, // L'expéditeur = l'utilisateur connecté
        to: receiverId, // Le destinataire = l'autre utilisateur
        content: content, // Le texte du message
        timestamp: DateTime.now(), // L'heure actuelle
      );

      // ÉTAPE 2 : Ajouter le message dans la sous-collection "messages"
      // .add() génère automatiquement un ID unique pour le document
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // ÉTAPE 3 : Mettre à jour le document chat principal
      // Le lastMessage est utilisé pour afficher un aperçu dans la liste des chats
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('Message envoyé: $content');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      _errorMessage = 'Impossible d\'envoyer le message';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retourne un Stream (flux temps réel) des messages d'une conversation.
  ///
  /// Les messages sont triés par timestamp croissant (du plus ancien au plus récent).
  /// Chaque fois qu'un nouveau message est ajouté dans Firestore, le Stream
  /// émet automatiquement la nouvelle liste complète.
  ///
  /// Utilisé dans ChatPage avec StreamBuilder pour afficher les messages
  /// en temps réel sans rechargement manuel.
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Tri chronologique
        .snapshots() // Écoute en temps réel (Stream)
        .map((snapshot) {
          // Convertit chaque document Firestore en objet Message
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.data()))
              .toList();
        });
  }

  /// Récupère la liste des conversations de l'utilisateur connecté (temps réel).
  ///
  /// Filtre les chats où l'utilisateur fait partie des participants.
  /// Trie par date du dernier message (conversation la plus récente en premier).
  ///
  /// Note : cette méthode n'est pas utilisée directement dans l'UI actuelle
  /// mais pourrait servir pour une page "Conversations récentes".
  Stream<List<Chat>> getUserChatsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        // arrayContains vérifie si currentUserId est dans le tableau "participants"
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true) // Plus récent en premier
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Chat.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
