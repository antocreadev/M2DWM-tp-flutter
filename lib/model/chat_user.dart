/// Modèle représentant un utilisateur de l'application Chat
class ChatUser {
  final String id;
  final String displayName;
  final String email;
  final String bio;
  final String avatarBase64; // Stockage de l'avatar en base64

  ChatUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.avatarBase64 = '',
  });

  /// Convertit un document Firestore en objet ChatUser
  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      avatarBase64: map['avatarBase64'] ?? '',
    );
  }

  /// Convertit l'objet ChatUser en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'avatarBase64': avatarBase64,
    };
  }

  /// Crée une copie de l'utilisateur avec certains champs modifiés
  ChatUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? bio,
    String? avatarBase64,
  }) {
    return ChatUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }
}
