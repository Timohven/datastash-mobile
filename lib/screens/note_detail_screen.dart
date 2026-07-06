// lib/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'login_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _textController;
  bool _isLoading = false;
  bool _hasChanges = false; // отслеживаем были ли изменения

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.text);

    // Слушаем изменения текста
    _textController.addListener(() {
      final changed = _textController.text != widget.note.text;
      if (changed != _hasChanges) {
        setState(() => _hasChanges = changed);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final token = await AuthService.getToken();
    if (token == null) {
      _onTokenExpired();
      return;
    }

    final success = await NoteService.updateNote(
      token: token,
      noteId: widget.note.noteId,
      noteType: widget.note.noteType,
      text: _textController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Возвращаем true — сигнал для NotesScreen обновить список
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении')),
      );
    }
  }

  void _onTokenExpired() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.noteType),
        actions: [
          // Кнопка сохранить — только если есть изменения
          if (_hasChanges)
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Сохранить',
                    onPressed: _onSave,
                  ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _textController,
          maxLines: null,         // растягивается на весь экран
          expands: true,          // занимает всё доступное пространство
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: InputBorder.none, // без рамки — чистый редактор
            hintText: 'Текст заметки...',
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}