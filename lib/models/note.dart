// lib/models/note.dart
class Note {
  final int noteId;
  final String author;
  final String noteType;
  final String text;
  final DateTime? createdAt;

  Note({
    required this.noteId,
    required this.author,
    required this.noteType,
    required this.text,
    this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: json['note_id'],
      author: json['author'],
      noteType: json['note_type'],
      text: json['text'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}