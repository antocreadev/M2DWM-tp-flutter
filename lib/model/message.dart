/// Modèle représentant un message dans une conversation
class Message {
  final String from;
  final String to;
  final String content;
  final DateTime timestamp;

  Message({
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
  });

  /// Convertit un document Firestore en objet Message
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// Convertit l'objet Message en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Crée une copie du message avec certains champs modifiés
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
