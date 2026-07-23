// lib/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../services/file_service.dart';
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
	
	bool get _isEditable =>
      widget.note.noteType == 'text' || widget.note.noteType == 'link';

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

  Future<void> _onOpenFile() async {
    final filename = widget.note.text.split(r'\').last.split('/').last;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Загрузка...'),
        ]),
      ),
    );
    try {
      await FileService.downloadAndOpen(
        serverFilePath: widget.note.text,
        filename: filename,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }
	
	void _onTokenExpired() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /*
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
	*/
	@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_noteTypeLabel(widget.note.noteType)),
        actions: [
          // Кнопка сохранить — только для текста/ссылки и только если есть изменения
          if (_isEditable && _hasChanges)
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24, height: 24,
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
        child: _isEditable
            ? TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Текст заметки...',
                ),
                style: const TextStyle(fontSize: 16),
              )
            : _buildFilePreview(),
      ),
    );
  }
	
	// Для файлов — показываем имя файла и кнопку открыть
  /*
	Widget _buildFilePreview() {
    final filename = widget.note.text.split(r'\').last.split('/').last;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _fileIcon(widget.note.noteType),
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          filename,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          widget.note.createdAt?.toString().substring(0, 16) ?? '',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _onOpenFile,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Открыть файл'),
        ),
      ],
    );
  }
	*/
	Widget _buildFilePreview() {
		final filename = widget.note.text.split(r'\').last.split('/').last;
		final thumbnailUrl = FileService.getThumbnailUrl(widget.note.text);

		return Column(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				// Превью вместо иконки
				FutureBuilder<String?>(
					future: AuthService.getToken(),
					builder: (context, snapshot) {
						if (!snapshot.hasData) {
							return const SizedBox(
								width: 200,
								height: 200,
								child: Center(child: CircularProgressIndicator()),
							);
						}
						return ClipRRect(
							borderRadius: BorderRadius.circular(8),
							child: Image.network(
								thumbnailUrl,
								width: 200,
								height: 200,
								fit: BoxFit.cover,
								headers: {'Authorization': 'Bearer ${snapshot.data}'},
								errorBuilder: (_, __, ___) => Icon(
									_fileIcon(widget.note.noteType),
									size: 80,
									color: Colors.grey.shade400,
								),
							),
						);
					},
				),
				const SizedBox(height: 16),
				Text(
					filename,
					textAlign: TextAlign.center,
					style: const TextStyle(fontSize: 16),
				),
				const SizedBox(height: 8),
				Text(
					widget.note.createdAt?.toString().substring(0, 16) ?? '',
					style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
				),
				const SizedBox(height: 32),
				ElevatedButton.icon(
					onPressed: _onOpenFile,
					icon: const Icon(Icons.open_in_new),
					label: const Text('Открыть файл'),
				),
			],
		);
	}

	String _noteTypeLabel(String noteType) {
    switch (noteType) {
      case 'text':  return 'Заметка';
      case 'link':  return 'Ссылка';
      case 'photo': return 'Фото';
      case 'video': return 'Видео';
      case 'pdf':   return 'PDF';
      case 'file':  return 'Файл';
      default:      return 'Заметка';
    }
  }

  IconData _fileIcon(String noteType) {
    switch (noteType) {
      case 'photo': return Icons.image;
      case 'video': return Icons.videocam;
      case 'pdf':   return Icons.picture_as_pdf;
      default:      return Icons.attach_file;
    }
  }
}