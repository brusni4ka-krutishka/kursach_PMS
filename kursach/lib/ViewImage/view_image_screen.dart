import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kursach/Registration/registration_screen.dart';

class ViewImageScreen extends StatefulWidget {
  final String imagePath;
  final String imageName;
  final String? description; // Описание изображения
  final int userId;

  const ViewImageScreen({
    required this.imagePath,
    required this.imageName,
    this.description,
    required this.userId,
  });

  @override
  _ViewImageScreenState createState() => _ViewImageScreenState();
}

class _ViewImageScreenState extends State<ViewImageScreen> {
  final dbHelper = DatabaseHelper();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final imageInfo = await dbHelper.getImageInfoByPath(widget.imagePath);
      if (imageInfo != null) {
        int imageId = imageInfo['ID'];
        List<Map<String, dynamic>> comments = await dbHelper.getCommentsByImageId(imageId);
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load comments.'),
        ),
      );
    }
  }

  Future<void> _addComment() async {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      try {
        final imageInfo = await dbHelper.getImageInfoByPath(widget.imagePath);
        if (imageInfo != null) {
          int imageId = imageInfo['ID'];
          Map<String, dynamic> comment = {
            'ImageID': imageId,
            'UserID': widget.userId,
            'Text': commentText,
            'DateAdded': DateTime.now().toIso8601String(),
          };
          await dbHelper.insertComment(comment);
          _commentController.clear();
          _loadComments();
        }
      } catch (e) {
        print('Error adding comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId, int userId) async {
    if (userId == widget.userId) {
      try {
        await dbHelper.deleteComment(commentId);
        _loadComments();
      } catch (e) {
        print('Error deleting comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are not authorized to delete this comment.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Image'),
        backgroundColor: Color(0xFFF48FB1),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: _addToFavorites,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.file(File(widget.imagePath)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Name:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.imageName,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              if (widget.description != null && widget.description!.isNotEmpty) ...[
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.description!,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
              ],
              Text(
                'Comments:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    child: ListTile(
                      title: Text(comment['Text']),
                      subtitle: Text(comment['Username']),
                      trailing: comment['UserID'] == widget.userId
                          ? IconButton(
                        icon: Icon(Icons.delete, color: Color(0xFFF48FB1)),
                        onPressed: () => _deleteComment(comment['ID'], comment['UserID']),
                      )
                          : null,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToFavorites() async {
    try {
      Map<String, dynamic> favorite = {
        'UserID': widget.userId,
        'ImageID': (await dbHelper.getImageInfoByPath(widget.imagePath))['ID'],
      };
      await dbHelper.insertFavorite(favorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites')),
      );
    }
  }
}
