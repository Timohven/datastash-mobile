// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import 'login_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  String _status = 'Готов принимать заметки';
  final List<String> _log = []; // история отправленных заметок за сессию

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _initSharingIntent();
  }

  Future<void> _loadUsername() async {
    final username = await AuthService.getUsername();
    setState(() => _username = username);
  }
  
  void _initSharingIntent() {
  ReceiveSharingIntent.instance
      .getMediaStream()
      .listen((List<SharedMediaFile> files) {
		if (files.isNotEmpty) {
		  _handleSharedFiles(files);
		  // Сбрасываем буфер после обработки
		  ReceiveSharingIntent.instance.reset();
		}
	});
  ReceiveSharingIntent.instance
      .getInitialMedia()
      .then((List<SharedMediaFile> files){
		if (files.isNotEmpty) {
		  _handleSharedFiles(files);
		  // Сбрасываем буфер после обработки
		  ReceiveSharingIntent.instance.reset();
		}
	});
	}

	void _handleSharedFiles(List<SharedMediaFile> files) {
	  for (var file in files) {
			switch (file.type) {
				case SharedMediaType.text:
				_sendTextNote(file.path);
				break;
				case SharedMediaType.image:
				_sendFileNote(file.path);
				break;
				case SharedMediaType.file:
				_sendFileNote(file.path);
				break;
				case SharedMediaType.video:  // ← добавили
				_sendFileNote(file.path);
				break;
				default:
				_sendTextNote(file.path);
			}
	  }
	}

	Future<void> _sendTextNote(String text) async {
	  setState(() => _status = '⏳ Отправляю текст...');

	  final token = await AuthService.getToken();
	  if (token == null) { _onTokenExpired(); return; }

final username = await AuthService.getUsername();
print('SEND NOTE — username: $username, token: ${token?.substring(0, 20)}...');

	  // Определяем тип на клиенте примитивно — сервер всё равно перепроверит
	  final noteType = _detectType(text);

	  final success = await NoteService.createNote(
			token: token,
			text: text,
			noteType: noteType,
	  );

	  if (!mounted) return;
	  if (success) {
			setState(() {
				_status = '✅ Сохранено ($noteType)';
				_log.insert(0, '[$noteType] $text');
			});
	  } else {
			setState(() => _status = '❌ Ошибка при сохранении');
	  }
	}

	Future<void> _sendFileNote(String filePath) async {
	  setState(() => _status = '⏳ Загружаю файл...');

	  final token = await AuthService.getToken();
	  if (token == null) { _onTokenExpired(); return; }

final username = await AuthService.getUsername();
print('SEND NOTE — username: $username, token: ${token?.substring(0, 20)}...');

	  final success = await NoteService.uploadFile(
		token: token,
		filePath: filePath,
	  );

	  if (!mounted) return;
	  if (success) {
			setState(() {
				_status = '✅ Файл сохранён';
				_log.insert(0, '[file] $filePath');
			});
	  } else {
			setState(() => _status = '❌ Ошибка при загрузке файла');
	  }
	}

	// Примитивное определение типа на клиенте для текста/ссылок
	String _detectType(String text) {
	  final urlPattern = RegExp(
		r'^https?://[\w\-]+(\.[\w\-]+)+([\w.,@?^=%&:/~+#\-_]*)?$',
		caseSensitive: false,
	  );
	  return urlPattern.hasMatch(text.trim()) ? 'link' : 'text';
	}

  // Токен протух — разлогинить и отправить на экран логина
  void _onTokenExpired() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _onLogout() async {
    ReceiveSharingIntent.instance.reset(); // ← сброс буфера перед выходом
		await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username != null ? 'DataStash — $_username' : 'DataStash'),
        actions: [
          IconButton(
						icon: const Icon(Icons.list),
						tooltip: 'Мои заметки',
						onPressed: () => Navigator.push(
							context,
							MaterialPageRoute(builder: (_) => const NotesScreen()),
						),
					),
					IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Статус последней операции
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Заголовок лога
            if (_log.isNotEmpty) ...[
              const Text(
                'Отправлено за сессию:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Список отправленных заметок
              Expanded(
                child: ListView.separated(
                  itemCount: _log.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.note_alt_outlined),
                      title: Text(
                        _log[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Подсказка если ничего не отправлено
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Поделитесь текстом или ссылкой\nчерез меню Android',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }
}