class JournalEntry {
  final int? id;
  final String title;
  final String note;
  final String createdAt; // ISO8601 UTC

  JournalEntry({
    this.id,
    required this.title,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'note': note, 'created_at': createdAt};
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      note: (map['note'] ?? '') as String,
      createdAt:
          (map['created_at'] as String?) ??
          DateTime.now().toUtc().toIso8601String(),
    );
  }
}
