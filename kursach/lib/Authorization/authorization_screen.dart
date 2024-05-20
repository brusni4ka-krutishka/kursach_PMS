import 'package:flutter/material.dart';
import 'package:kursach/Registration/registration_screen.dart';
import 'package:kursach/Gallery/galleryPage_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthorizationScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper(); // Создаем экземпляр класса DatabaseHelper

  Future<void> _loginUser(BuildContext context) async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      // Проверяем пользователя по его логину
      Map<String, dynamic>? user = await dbHelper.getUserByUsername(username);

      if (user != null) {
        // Если пользователь найден, проверяем введенный пароль
        String storedPasswordHash = user['PasswordHash'];
        String enteredPasswordHash = _generatePasswordHash(password);

        if (storedPasswordHash == enteredPasswordHash) {
          // Пароль верный, переходим на страницу с галереей
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImageGalleryPage(userId: user['ID'])),
          );
          return; // Завершаем метод, чтобы избежать показа сообщения о неверных данных
        }
      }
    }

    // Если логин или пароль неверные, показываем сообщение об ошибке
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid username or password.'),
      ),
    );
  }

  String _generatePasswordHash(String password) {
    // Ваша реализация метода генерации хэша пароля
    var bytes = utf8.encode(password);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: SingleChildScrollView( // Добавляем SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'LOGIN',
              style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Color(0xFFF48FB1),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'TO CONTINUE',
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                color: Color(0xFFF48FB1),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                labelText: 'Username',
                labelStyle: TextStyle(color: Color(0xFFF48FB1)),
                hintText: 'Enter your username',
                hintStyle: TextStyle(color: Color(0xFFF48FB1)),
                hintMaxLines: 1,
              ),
              style: TextStyle(color: Color(0xFFF48FB1)),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF48FB1)),
                ),
                labelText: 'Password',
                labelStyle: TextStyle(color: Color(0xFFF48FB1)),
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Color(0xFFF48FB1)),
                hintMaxLines: 1,
              ),
              style: TextStyle(color: Color(0xFFF48FB1)),
              obscureText: true,
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () => _loginUser(context),
              child: Text(
                'LOG IN',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
