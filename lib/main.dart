import 'package:flutter/material.dart';
import 'lock_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aqilah\'s Diary',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: LockScreen(),
    );
  }
}