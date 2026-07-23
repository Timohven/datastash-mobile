// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'login_screen.dart';
import 'note_detail_screen.dart';
import '../services/file_service.dart';

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

  Future<void> _deleteNote(Note note) async {
		final token = await AuthService.getToken();
		if (token == null) { _onTokenExpired(); return; }

		final success = await NoteService.deleteNote(
			token: token,
			noteId: note.noteId,
		);

		if (!mounted) return;

		if (success) {
			setState(() => _notes!.remove(note));
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Заметка удалена')),
			);
		} else {
			// Если не удалось — возвращаем заметку в список
			_loadNotes();
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Ошибка при удалении')),
			);
		}
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
					return Dismissible(
						key: Key(note.noteId.toString()),
						direction: DismissDirection.endToStart, // свайп справа налево
						background: Container(
							alignment: Alignment.centerRight,
							padding: const EdgeInsets.only(right: 20),
							decoration: BoxDecoration(
								color: Colors.red,
								borderRadius: BorderRadius.circular(12),
							),
							child: const Icon(Icons.delete, color: Colors.white, size: 32),
						),
						confirmDismiss: (_) async {
							// Диалог подтверждения
							return await showDialog<bool>(
								context: context,
								builder: (ctx) => AlertDialog(
									title: const Text('Удалить заметку?'),
									content: const Text('Это действие нельзя отменить'),
									actions: [
										TextButton(
											onPressed: () => Navigator.pop(ctx, false),
											child: const Text('Отмена'),
										),
										TextButton(
											onPressed: () => Navigator.pop(ctx, true),
											child: const Text('Удалить', style: TextStyle(color: Colors.red)),
										),
									],
								),
							);
						},
						onDismissed: (_) => _deleteNote(note),
						child: Card(
							child: ListTile(
								leading: GestureDetector(
									onTap: note.noteType != 'text' && note.noteType != 'link'
											? () => _openFile(note)
											: null,
									child: _noteTypeIcon(note),
								),
								title: _noteContent(note),
								subtitle: Text(
									_formatDate(note.createdAt),
									style: const TextStyle(fontSize: 12),
								),
								onTap: () async {
									final result = await Navigator.push(
										context,
										MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
									);
									if (result == 'updated') _loadNotes();
								},
							),
						),
					);
					/*
					return Card(
						child: ListTile(
							leading: GestureDetector(
								onTap: note.noteType != 'text' && note.noteType != 'link'
										? () => _openFile(note)   // ← нажатие на иконку открывает файл
										: null,
								child: _noteTypeIcon(note),
							),
							title: _noteContent(note),
							subtitle: Text(
								_formatDate(note.createdAt),
								style: const TextStyle(fontSize: 12),
							),
							onTap: () async {
								if (note.noteType == 'text' || note.noteType == 'link') {
									// Текст и ссылки — открываем редактор
									final updated = await Navigator.push(
										context,
										MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
									);
									if (updated == true) _loadNotes();
								} else {
									// Файлы — скачиваем и открываем
									_openFile(note);
								}
							},
						),
					);
					*/
				},
      ),
    );
  }

	Widget _noteTypeIcon(Note note) {
final url = FileService.getThumbnailUrl(note.text);
print('THUMBNAIL URL: $url');
		// Для типов с превью — показываем картинку
		if (note.noteType == 'photo' || 
				note.noteType == 'video' ||
				note.noteType == 'pdf' ||				
				note.noteType == 'file') {
			return FutureBuilder<String?>(
				future: AuthService.getToken(),
				builder: (context, snapshot) {
					if (!snapshot.hasData) {
						return const Icon(Icons.hourglass_empty, size: 48);
					}
					return ClipRRect(
						borderRadius: BorderRadius.circular(4),
						child: Image.network(
							FileService.getThumbnailUrl(note.text),
							width: 48,
							height: 48,
							fit: BoxFit.cover,
							headers: {'Authorization': 'Bearer ${snapshot.data}'},
							errorBuilder: (_, __, ___) => _fallbackIcon(note.noteType),
						),
					);
				},
			);
		}
		return _fallbackIcon(note.noteType);
	}

	// Иконка если превью нет или не загрузилось
	Widget _fallbackIcon(String noteType) {
		switch (noteType) {
			case 'link':  return const Icon(Icons.link,              color: Colors.blue);
			case 'photo': return const Icon(Icons.image,             color: Colors.green);
			case 'video': return const Icon(Icons.videocam,          color: Colors.red);
			case 'pdf':   return const Icon(Icons.picture_as_pdf,    color: Colors.red);
			case 'file':  return const Icon(Icons.attach_file,       color: Colors.orange);
			default:      return const Icon(Icons.note_alt_outlined, color: Colors.indigo);
		}
	}
	
	Widget _noteContent(Note note) {
		switch (note.noteType) {
			case 'photo':
				return Text(
					note.text.split(r'\').last.split('/').last, // только имя файла
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(color: Colors.grey),
				);
			case 'video':
				return Text(
					note.text.split(r'\').last.split('/').last,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(color: Colors.grey),
				);
			case 'file':
				return Text(
					note.text.split(r'\').last.split('/').last,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(color: Colors.grey),
				);
			case 'link':
				return Text(
					note.text,
					maxLines: 2,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(color: Colors.blue),
				);
			default: // text
				return Text(
					note.text,
					maxLines: 3,
					overflow: TextOverflow.ellipsis,
				);
		}
	}
	
	Future<void> _openFile(Note note) async {
		final filename = note.text.split(r'\').last.split('/').last;

		// Показываем прогресс
		showDialog(
			context: context,
			barrierDismissible: false,
			builder: (_) => const AlertDialog(
				content: Row(
					children: [
						CircularProgressIndicator(),
						SizedBox(width: 16),
						Text('Загрузка...'),
					],
				),
			),
		);

		try {
			await FileService.downloadAndOpen(
				serverFilePath: note.text,  // путь как в БД
				filename: filename,
			);
		} catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Ошибка: $e')),
			);
		} finally {
			if (mounted) Navigator.pop(context); // закрыть диалог прогресса
		}
	}
}