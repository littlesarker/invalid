import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gallery_page.dart';
import 'gallery_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GalleryProvider()..loadImages(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: GalleryPage(),
    );
  }
}