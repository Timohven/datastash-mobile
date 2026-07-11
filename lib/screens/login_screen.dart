// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Контроллеры читают текст из полей ввода
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;  // показывать ли спиннер вместо кнопки
  String? _errorMessage;    // текст ошибки под кнопкой

  @override
  void dispose() {
    // Освобождаем ресурсы когда экран закрывается
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
print('КНОПКА НАЖАТА');  // ← сразу видно вызывается ли вообще
    // Убираем ошибку и показываем спиннер
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await AuthService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
print('token: $token');  // null если логин не прошёл
    if (!mounted) return;

    if (token != null) {
      // Токен получен — переходим на главный экран
      // pushReplacement чтобы нельзя было вернуться назад на логин
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Показываем ошибку
      setState(() {
        _isLoading = false;
        _errorMessage = 'Неверный логин или пароль';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DataStash — Вход')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Поле логина
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next, // переход на след поле по Enter
            ),

            const SizedBox(height: 16),

            // Поле пароля
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,                    // скрывает символы
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onLoginPressed(), // Enter = нажать кнопку
            ),

            const SizedBox(height: 24),

            // Кнопка или спиннер
            SizedBox(
              width: double.infinity, // кнопка во всю ширину
              height: 48,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _onLoginPressed,
                      child: const Text('Войти', style: TextStyle(fontSize: 16)),
                    ),
            ),

            // Сообщение об ошибке
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

          ],
        ),
      ),
    );
  }
}