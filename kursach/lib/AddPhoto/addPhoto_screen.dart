import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kursach/Registration/registration_screen.dart';
import 'package:kursach/Gallery/galleryPage_screen.dart';

class AddPhotoScreen extends StatelessWidget {
  final String imagePath;
  final int userId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Function updateImagePaths; // Добавляем поле функции обратного вызова

  AddPhotoScreen({required this.imagePath, required this.userId, required this.updateImagePaths});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Photo'),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // Отобразите выбранное изображение здесь
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.file(File(imagePath)),
              ),
              SizedBox(height: 20),
              // Добавьте поля для ввода названия и описания изображения
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter image title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF48FB1)),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter image description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF48FB1)),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Добавьте кнопку "Добавить"
              ElevatedButton(
                onPressed: () async {
                  try {
                    DatabaseHelper dbHelper = DatabaseHelper();
                    await dbHelper.insertImage({
                      'UserID': userId,
                      'Name': _titleController.text,
                      'Description': _descriptionController.text,
                      'ImagePath': imagePath,
                      'DateAdded': DateTime.now().toString(),
                    });
                    // Вызываем функцию обратного вызова для обновления списка изображений на главном экране
                    updateImagePaths();
                    // Возвращаемся на предыдущий экран после успешной вставки данных
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error adding image to database: $e');
                    // Сообщаем пользователю об ошибке
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add image.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF48FB1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                child: Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
