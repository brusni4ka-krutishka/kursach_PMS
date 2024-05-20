import 'package:flutter/material.dart';
import 'package:kursach/Authorization/authorization_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.pink, // Установить основной цвет для приложения
      ),
      home: RegistrationScreen(),
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'kursach.db');

    _database = await openDatabase(path, version: 1, onCreate: _createDb);
    return _database!;
  }


  Future<List<Map<String, dynamic>>> getAllImages() async {
    final Database db = await database;
    final List<Map<String, dynamic>> images = await db.query('images');
    return images;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Users (
      ID INTEGER PRIMARY KEY,
      Name TEXT,
      PasswordHash TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE Images (
      ID INTEGER PRIMARY KEY,
      UserID INTEGER,
      Name TEXT,
      Description TEXT,
      ImagePath TEXT,
      DateAdded TEXT,
      FOREIGN KEY (UserID) REFERENCES Users(ID)
    )
  ''');

    await db.execute('''
    CREATE TABLE Comments (
      ID INTEGER PRIMARY KEY,
      ImageID INTEGER,
      UserID INTEGER,
      Text TEXT,
      DateAdded TEXT,
      FOREIGN KEY (ImageID) REFERENCES Images(ID),
      FOREIGN KEY (UserID) REFERENCES Users(ID)
    )
  ''');

    await db.execute('''
    CREATE TABLE Favorites (
      UserID INTEGER,
      ImageID INTEGER,
      FOREIGN KEY (UserID) REFERENCES Users(ID),
      FOREIGN KEY (ImageID) REFERENCES Images(ID),
      PRIMARY KEY (UserID, ImageID)
    )
  ''');
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Users', row);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    Database db = await database;
    return await db.query('Users');
  }

Future<Map<String, dynamic>?> getUserByUsername(String username) async {
  Database db = await database;
  List<Map<String, dynamic>> users = await db.query(
    'Users',
    where: 'Name = ?',
    whereArgs: [username],
  );
  return users.isNotEmpty ? users.first : null;
}
  Future<int> insertImage(Map<String, dynamic> image) async {
    Database db = await database;
    return await db.insert('Images', image);
  }

  Future<List<Map<String, dynamic>>> getImagesByUserId(int userId) async {
    Database db = await database;
    List<Map<String, dynamic>> images = await db.query(
      'Images',
      where: 'UserID = ?',
      whereArgs: [userId],
    );
    return images;
  }


  Future<void> deleteImageByPath(String imagePath) async {
    Database db = await database;
    await db.delete(
      'Images',
      where: 'ImagePath = ?',
      whereArgs: [imagePath],
    );
  }
// Метод для получения информации об изображении по его пути
  Future<Map<String, dynamic>> getImageInfoByPath(String imagePath) async {
    final db = await database;
    var result = await db.query('Images', where: 'ImagePath = ?', whereArgs: [imagePath]);
    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception('Image not found in database');
    }
  }

  Future<void> insertFavorite(Map<String, dynamic> favorite) async {
    final db = await database;
    await db.insert('Favorites', favorite);
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    final db = await database;
    return await db.query('Favorites', where: 'UserID = ?', whereArgs: [userId]);
  }

  Future<void> deleteFavorite(int userId, int imageId) async {
    final db = await database;
    await db.delete('Favorites', where: 'UserID = ? AND ImageID = ?', whereArgs: [userId, imageId]);
  }

  Future<Map<String, dynamic>?> getImageInfoById(int imageId) async {
    final db = await database;
    var result = await db.query('Images', where: 'ID = ?', whereArgs: [imageId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> insertComment(Map<String, dynamic> comment) async {
    final db = await database;
    await db.insert('Comments', comment);
  }

  Future<List<Map<String, dynamic>>> getCommentsByImageId(int imageId) async {
    final db = await database;
    final comments = await db.rawQuery('''
      SELECT Comments.*, Users.Name as Username FROM Comments
      INNER JOIN Users ON Comments.UserID = Users.ID
      WHERE Comments.ImageID = ?
    ''', [imageId]);
    return comments;
  }

  Future<void> deleteComment(int commentId) async {
    final db = await database;
    await db.delete('Comments', where: 'ID = ?', whereArgs: [commentId]);
  }










}

class RegistrationScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController =
  TextEditingController();

  Future<void> _registerUser(BuildContext context) async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    String retypePassword = retypePasswordController.text.trim();

    if (username.isNotEmpty &&
        password.isNotEmpty &&
        password == retypePassword) {
      String passwordHash = _generatePasswordHash(password);

// Проверка наличия пользователя с таким именем
      Map<String, dynamic>? existingUser = await dbHelper.getUserByUsername(
          username);
      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User with this username already exists.'),
          ),
        );
        return;
      }

      Map<String, dynamic> user = {
        'Name': username,
        'PasswordHash': passwordHash,
      };

      int id = await dbHelper.insertUser(user);
      print('User registered with ID: $id');

      await _displayUsers();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthorizationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields correctly.'),
        ),
      );
    }
  }


  Future<void> _displayUsers() async {
    List<Map<String, dynamic>> users = await dbHelper.getAllUsers();
    print('All users:');
    for (Map<String, dynamic> user in users) {
      print(
          'ID: ${user['ID']}, Name: ${user['Name']}, Password: ${user['PasswordHash']}');
    }
  }

  String _generatePasswordHash(String password) {
    var bytes = utf8.encode(password);
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'SIGN UP',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headline6!
                        .copyWith(
                      color: Color(0xFFF48FB1),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'FOR YOUR ACCOUNT',
                    style: Theme
                        .of(context)
                        .textTheme
                        .subtitle1!
                        .copyWith(
                      color: Color(0xFFF48FB1),
                      // Более нежный розовый цвет текста
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.0),
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
                  hintText: 'username',
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
                  hintText: 'your password',
                  hintStyle: TextStyle(color: Color(0xFFF48FB1)),
                  hintMaxLines: 1,
                ),
                style: TextStyle(color: Color(0xFFF48FB1)),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: retypePasswordController,
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
                  hintText: 'retype your password',
                  hintStyle: TextStyle(color: Color(0xFFF48FB1)),
                  hintMaxLines: 1,
                ),
                style: TextStyle(color: Color(0xFFF48FB1)),
                obscureText: true,
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () => _registerUser(context),
                child: Container(
                  width: 120,
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  alignment: Alignment.center,
                  child: Text(
                    'SIGN UP',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF48FB1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 4,
                ),
              ),
              SizedBox(height: 0),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AuthorizationScreen()),
                  );
                },
                child: Text(
                  'Have an account?',
                  style: TextStyle(color: Color(0xFFF48FB1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}