import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kursach/Registration/registration_screen.dart';
import 'package:kursach/ViewImage/view_image_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final int userId;

  const FavoritesScreen({required this.userId});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _favoriteImages = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteImages();
  }

  Future<void> _loadFavoriteImages() async {
    try {
      List<Map<String, dynamic>> favorites = await dbHelper.getFavorites(widget.userId);
      List<Map<String, dynamic>> favoriteImages = [];
      for (var favorite in favorites) {
        var imageInfo = await dbHelper.getImageInfoById(favorite['ImageID']);
        if (imageInfo != null) {
          favoriteImages.add(imageInfo);
        }
      }
      setState(() {
        _favoriteImages = favoriteImages;
      });
    } catch (e) {
      print('Error loading favorite images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load favorite images')),
      );
    }
  }

  Future<void> _removeFromFavorites(int imageId) async {
    try {
      await dbHelper.deleteFavorite(widget.userId, imageId);
      _loadFavoriteImages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _favoriteImages.length,
          itemBuilder: (context, index) {
            var imageInfo = _favoriteImages[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.file(File(imageInfo['ImagePath']), width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text(
                  imageInfo['Name'] ?? 'Unnamed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Color(0xFFF48FB1)),
                  onPressed: () {
                    _removeFromFavorites(imageInfo['ID']);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewImageScreen(
                        imagePath: imageInfo['ImagePath'],
                        imageName: imageInfo['Name'] ?? 'Unnamed',
                        description: imageInfo['Description'],
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
