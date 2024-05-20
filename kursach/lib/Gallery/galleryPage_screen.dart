import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kursach/Registration/registration_screen.dart';
import 'package:kursach/AddPhoto/addPhoto_screen.dart';
import 'package:kursach/ViewImage/view_image_screen.dart';
import 'package:kursach/Favorites/favorites_screen.dart';

class ImageGalleryPage extends StatefulWidget {
  final int userId;
  final ImagePicker _picker = ImagePicker();

  ImageGalleryPage({required this.userId});

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  List<String> _filteredImages = [];
  final dbHelper = DatabaseHelper();
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _imageNames = {};
  Map<String, String> _imageDescriptions = {};

  @override
  void initState() {
    super.initState();
    _loadImagesFromDatabase();
  }

  Future<void> _loadImagesFromDatabase() async {
    try {
      List<Map<String, dynamic>> images = await dbHelper.getAllImages();
      List<String> newImagePaths = [];
      Map<String, String> imageNames = {};
      Map<String, String> imageDescriptions = {};

      for (Map<String, dynamic> image in images) {
        String imagePath = image['ImagePath'];
        String imageName = image['Name'] ?? 'Unnamed';
        String imageDescription = image['Description'] ?? '';
        newImagePaths.add(imagePath);
        imageNames[imagePath] = imageName;
        imageDescriptions[imagePath] = imageDescription;
      }

      setState(() {
        _imagePaths = newImagePaths;
        _imageNames = imageNames;
        _imageDescriptions = imageDescriptions;
        _filterImages();
      });
    } catch (e) {
      print('Error loading images from database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load images from database.'),
        ),
      );
    }
  }

  Future<void> _pickImageAndSave() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final String imagePath = pickedFile.path;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPhotoScreen(
              imagePath: imagePath,
              userId: widget.userId,
              updateImagePaths: _loadImagesFromDatabase,
            ),
          ),
        );
      } else {
        throw Exception('Image picking failed');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image.'),
        ),
      );
    }
  }

  Future<void> _deleteImageFromDatabase(String imagePath) async {
    try {
      Map<String, dynamic> imageInfo = await dbHelper.getImageInfoByPath(imagePath);
      if (imageInfo != null) {
        int userId = imageInfo['UserID'];
        if (userId == widget.userId) {
          await dbHelper.deleteImageByPath(imagePath);
          setState(() {
            _imagePaths.remove(imagePath);
            _filterImages();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are not authorized to delete this image.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image not found in database.'),
          ),
        );
      }
    } catch (e) {
      print('Error deleting image from database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image.'),
        ),
      );
    }
  }

  Future<void> _performSearch() async {
    String query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _filterImages();
    });
  }

  void _filterImages() {
    if (_searchQuery.isEmpty) {
      _filteredImages = _imagePaths;
    } else {
      _filteredImages = _imagePaths.where((imagePath) {
        String imageName = _imageNames[imagePath] ?? 'Unnamed';
        return imageName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Gallery'),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _buildImageGrid(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesScreen(userId: widget.userId)),
              );
            },
            heroTag: 'favorites',
            child: Icon(Icons.favorite),
            backgroundColor: Color(0xFFF48FB1),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickImageAndSave,
            heroTag: 'add',
            child: Icon(Icons.add),
            backgroundColor: Color(0xFFF48FB1),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    try {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        padding: const EdgeInsets.all(10.0),
        itemCount: _filteredImages.length,
        itemBuilder: (context, index) {
          String imagePath = _filteredImages[index];
          String imageName = _imageNames[imagePath] ?? 'Unnamed';
          String imageDescription = _imageDescriptions[imagePath] ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewImageScreen(
                    imagePath: imagePath,
                    imageName: imageName,
                    description: imageDescription,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      imageName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      imageDescription,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 8.0),
                ],
              ),
            ),
            onLongPress: () {
              _deleteImageFromDatabase(imagePath);
            },
          );
        },
      );
    } catch (e) {
      print('Error building image grid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image.'),
        ),
      );
      return SizedBox();
    }
  }
}
