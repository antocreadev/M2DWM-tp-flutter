// =============================================================================
// chat_user.dart - MODÈLE DE DONNÉES : UTILISATEUR
// =============================================================================
// Ce fichier définit la structure de données d'un utilisateur de l'application.
//
// RÔLE D'UN MODEL dans le pattern MVVM :
//   - Représenter les DONNÉES pures (pas de logique métier complexe)
//   - Définir la structure des objets stockés dans Firestore (base de données)
//   - Fournir des méthodes de sérialisation (conversion objet <-> Map/JSON)
//
// Un Model est comme un "moule" : il définit la forme des données.
// Ici, un ChatUser a un id, un nom, un email, une bio et un avatar.
//
// Collection Firestore correspondante : "users"
// =============================================================================

/// Modèle représentant un utilisateur de l'application Chat.
///
/// Chaque utilisateur est stocké dans Firestore dans la collection "users"
/// avec son UID Firebase Auth comme identifiant de document.
///
/// Exemple de document Firestore :
/// ```
/// users/abc123 {
///   id: "abc123",
///   displayName: "Jean Dupont",
///   email: "jean@email.com",
///   bio: "Hello !",
///   avatarBase64: "iVBORw0KGgo..." (image encodée en texte)
/// }
/// ```
class ChatUser {
  /// Identifiant unique de l'utilisateur (= UID Firebase Auth)
  final String id;

  /// Nom affiché dans l'app (choisi par l'utilisateur lors de l'inscription)
  final String displayName;

  /// Adresse email utilisée pour la connexion
  final String email;

  /// Description courte du profil (optionnelle, vide par défaut)
  final String bio;

  /// Avatar de l'utilisateur encodé en base64 (optionnel, vide par défaut).
  /// On stocke l'image directement en texte dans Firestore plutôt que d'utiliser
  /// Firebase Storage, ce qui simplifie le code mais limite la taille des images.
  final String avatarBase64;

  /// Constructeur de ChatUser.
  /// Les champs [id], [displayName] et [email] sont obligatoires (required).
  /// Les champs [bio] et [avatarBase64] sont optionnels avec une valeur par défaut vide.
  ChatUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.avatarBase64 = '',
  });

  /// Factory constructor : crée un ChatUser à partir d'un Map (données Firestore).
  ///
  /// Firestore retourne les documents sous forme de Map<String, dynamic>.
  /// Cette méthode convertit ce Map en objet ChatUser utilisable dans le code Dart.
  ///
  /// L'opérateur ?? '' fournit une valeur par défaut vide si le champ est null
  /// (protection contre les données manquantes dans Firestore).
  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      avatarBase64: map['avatarBase64'] ?? '',
    );
  }

  /// Convertit l'objet ChatUser en Map pour l'envoyer à Firestore.
  ///
  /// C'est l'opération inverse de fromMap().
  /// Firestore n'accepte que des Map<String, dynamic>, pas des objets Dart.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'avatarBase64': avatarBase64,
    };
  }

  /// Crée une COPIE de l'utilisateur avec certains champs modifiés.
  ///
  /// Comme les champs sont "final" (immutables), on ne peut pas les modifier
  /// directement. copyWith() crée un nouvel objet avec les valeurs souhaitées.
  ///
  /// Exemple : user.copyWith(bio: "Nouvelle bio") retourne un nouvel objet
  /// avec la nouvelle bio mais tous les autres champs identiques.
  ChatUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? bio,
    String? avatarBase64,
  }) {
    return ChatUser(
      id: id ?? this.id, // Si id est null, on garde l'ancien
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
    );
  }
}
