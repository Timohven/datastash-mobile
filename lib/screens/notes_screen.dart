// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'login_screen.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note>? _notes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    if (token == null) {
      _onTokenExpired();
      return;
    }

    final notes = await NoteService.getNotes(token: token);
    if (!mounted) return;

    if (notes == null) {
      // Проверяем — токен протух или просто сетевая ошибка
      final valid = await AuthService.isTokenValid();
      if (!mounted) return;
      if (!valid) {
        _onTokenExpired();
        return;
      }
      setState(() {
        _error = 'Не удалось загрузить заметки';
        _isLoading = false;
      });
    } else {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _onTokenExpired() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        actions: [
          // Кнопка обновить
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Загрузка
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ошибка
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotes,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Пустой список
    if (_notes == null || _notes!.isEmpty) {
      return const Center(
        child: Text('Заметок пока нет', style: TextStyle(color: Colors.grey)),
      );
    }

    // Список заметок
    return RefreshIndicator(
      onRefresh: _loadNotes, // потянуть вниз для обновления
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _notes!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
		  final note = _notes![index];
		  return Card(
			child: ListTile(
			  leading: _noteTypeIcon(note.noteType),
			  title: Text(
				note.text,
				maxLines: 3,
				overflow: TextOverflow.ellipsis,
			  ),
			  subtitle: Text(
				_formatDate(note.createdAt),
				style: const TextStyle(fontSize: 12),
			  ),
			  onTap: () async {
				// Открываем экран редактирования
				// Если вернулся true — заметка была изменена, обновляем список
				final updated = await Navigator.push(
				  context,
				  MaterialPageRoute(
					builder: (_) => NoteDetailScreen(note: note),
				  ),
				);
				if (updated == true) _loadNotes();
			  },
			),
		  );
		},
      ),
    );
  }

  Widget _noteTypeIcon(String noteType) {
  switch (noteType) {
    case 'link':
      return const Icon(Icons.link,          color: Colors.blue);
    case 'photo':
      return const Icon(Icons.image,         color: Colors.green);
    case 'video':
      return const Icon(Icons.videocam,      color: Colors.red);
    case 'file':
      return const Icon(Icons.attach_file,   color: Colors.orange);
    default:
      return const Icon(Icons.note_alt_outlined, color: Colors.indigo);
  }
}
}