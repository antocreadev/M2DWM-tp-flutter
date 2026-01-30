// =============================================================================
// chat.dart - MODÈLE DE DONNÉES : CONVERSATION
// =============================================================================
// Ce fichier définit la structure de données d'une conversation (chat) entre
// deux utilisateurs.
//
// Chaque conversation est identifiée par un ID unique construit à partir
// des UIDs des deux participants, triés par ordre alphabétique.
// Exemple : si user "abc" parle avec user "xyz", le chatId = "abc_xyz"
// Cela garantit que la même conversation a toujours le même ID,
// peu importe qui l'a initiée.
//
// Collection Firestore correspondante : "chats"
// Sous-collection : "chats/{chatId}/messages" (contient les messages)
// =============================================================================

/// Modèle représentant une conversation entre deux utilisateurs.
///
/// Exemple de document Firestore :
/// ```
/// chats/abc123_xyz789 {
///   participants: ["abc123", "xyz789"],
///   lastMessage: "Salut !",
///   lastMessageTime: 1706000000000  (timestamp en millisecondes)
/// }
/// ```
class Chat {
  /// Identifiant unique du chat (format : "{uid1}_{uid2}" triés alphabétiquement)
  final String id;

  /// Liste des UIDs des deux participants à la conversation
  final List<String> participants;

  /// Dernier message envoyé dans la conversation (pour l'aperçu dans la liste)
  /// Peut être null si aucun message n'a encore été envoyé
  final String? lastMessage;

  /// Horodatage du dernier message (pour trier les conversations par date)
  /// Peut être null si aucun message n'a encore été envoyé
  final DateTime? lastMessageTime;

  /// Constructeur de Chat.
  /// [id] et [participants] sont obligatoires.
  /// [lastMessage] et [lastMessageTime] sont optionnels (null au début).
  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
  });

  /// Factory constructor : crée un Chat à partir d'un Map Firestore.
  ///
  /// Prend un paramètre supplémentaire [id] car dans Firestore,
  /// l'ID du document n'est PAS inclus dans les données du document,
  /// il faut le récupérer séparément via doc.id.
  ///
  /// Le timestamp est stocké en millisecondes dans Firestore et converti
  /// en objet DateTime pour l'utiliser facilement dans le code Dart.
  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      // List<String>.from() convertit la liste dynamique Firestore en liste typée
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      // Conversion millisecondes -> DateTime (si le champ existe)
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
    );
  }

  /// Convertit l'objet Chat en Map pour Firestore.
  /// Note : l'ID n'est PAS inclus car il est utilisé comme identifiant de document.
  /// Le DateTime est converti en millisecondes pour le stockage.
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
    };
  }

  /// Crée une copie du chat avec certains champs modifiés.
  /// Même principe que ChatUser.copyWith() - les objets sont immutables.
  Chat copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
