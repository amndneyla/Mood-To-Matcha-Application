class JournalEntry {
  final int? id;
  final String title;
  final String note;
  final String createdAt;
  final String createdLocal;
  final String zone;
  final String userId;

  JournalEntry({
    this.id,
    required this.title,
    required this.note,
    required this.createdAt,
    required this.createdLocal,
    required this.zone,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'created_at': createdAt,
      'created_local': createdLocal,
      'zone': zone,
      'user_id': userId,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      note: (map['note'] ?? '') as String,
      createdAt:
          (map['created_at'] as String?) ??
          DateTime.now().toUtc().toIso8601String(),
      createdLocal:
          (map['created_local'] as String?) ?? DateTime.now().toIso8601String(),
      zone: (map['zone'] as String?) ?? 'WIB',
      userId: (map['user_id'] as String?) ?? '',
    );
  }
}
