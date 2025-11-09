class Nota {
  final String id;
  final String title;
  final String conteudo;
  final DateTime timestamp;
  final String userId;

  Nota({
    required this.id,
    required this.title,
    required this.conteudo,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'conteudo': conteudo,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
      };

  factory Nota.fromJson(Map<String, dynamic> json) => Nota(
        id: json['id'],
        title: json['title'],
        conteudo: json['conteudo'],
        timestamp: DateTime.parse(json['timestamp']),
        userId: json['userId'] ?? '',
      );
}