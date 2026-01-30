// =============================================================================
// message.dart - MODÈLE DE DONNÉES : MESSAGE
// =============================================================================
// Ce fichier définit la structure de données d'un message individuel
// envoyé dans une conversation.
//
// Les messages sont stockés dans une SOUS-COLLECTION Firestore :
//   chats/{chatId}/messages/{messageId}
//
// Chaque message contient l'expéditeur, le destinataire, le contenu et
// l'horodatage. L'ID du message est généré automatiquement par Firestore.
// =============================================================================

/// Modèle représentant un message dans une conversation.
///
/// Exemple de document Firestore :
/// ```
/// chats/abc_xyz/messages/auto_generated_id {
///   from: "abc123",         // UID de l'expéditeur
///   to: "xyz789",           // UID du destinataire
///   content: "Bonjour !",   // Texte du message
///   timestamp: 1706000000000 // Horodatage en millisecondes
/// }
/// ```
class Message {
  /// UID de l'expéditeur du message (celui qui l'a envoyé)
  final String from;

  /// UID du destinataire du message (celui qui le reçoit)
  final String to;

  /// Contenu textuel du message
  final String content;

  /// Horodatage de l'envoi du message
  /// Utilisé pour trier les messages chronologiquement et afficher l'heure
  final DateTime timestamp;

  /// Constructeur de Message. Tous les champs sont obligatoires.
  Message({
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
  });

  /// Factory constructor : crée un Message à partir d'un Map Firestore.
  ///
  /// Le timestamp est stocké en millisecondes dans Firestore et converti
  /// en DateTime. Si le timestamp est absent, on utilise 0 (1er janvier 1970).
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// Convertit l'objet Message en Map pour Firestore.
  /// Le DateTime est converti en millisecondes (format attendu par Firestore).
  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Crée une copie du message avec certains champs modifiés.
  Message copyWith({
    String? from,
    String? to,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      from: from ?? this.from,
      to: to ?? this.to,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
