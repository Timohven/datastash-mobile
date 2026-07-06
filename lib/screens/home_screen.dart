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
    // Приложение уже открыто — пришёл новый Share
    ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
      for (var file in files) {
        if (file.type == SharedMediaType.text) {
          _sendNote(file.path);
        }
      }
    });

    // Приложение было закрыто — открылось через Share
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> files) {
      for (var file in files) {
        if (file.type == SharedMediaType.text) {
          _sendNote(file.path);
        }
      }
    });
  }

  Future<void> _sendNote(String text) async {
    setState(() => _status = '⏳ Отправляю...');

    final token = await AuthService.getToken();
    if (token == null) {
      _onTokenExpired();
      return;
    }

    final success = await NoteService.createNote(
      token: token,
      text: text,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _status = '✅ Сохранено';
        _log.insert(0, text); // добавляем в начало списка
      });
    } else {
      // Возможно токен протух — проверяем
      final valid = await AuthService.isTokenValid();
      if (!mounted) return;
      if (!valid) {
        _onTokenExpired();
      } else {
        setState(() => _status = '❌ Ошибка при сохранении');
      }
    }
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