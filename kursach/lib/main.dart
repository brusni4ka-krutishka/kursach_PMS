import 'package:flutter/material.dart';
import 'package:kursach/Registration/registration_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.pink, // Set primary color for the app
      ),
      home: RegistrationScreen(),
    );
  }
}
