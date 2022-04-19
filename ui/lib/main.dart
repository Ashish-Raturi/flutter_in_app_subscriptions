import 'package:flutter/material.dart';

import 'home_page.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter In App Purchase',
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}
