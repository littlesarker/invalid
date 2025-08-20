import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'gallery_provider.dart';

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    // If no permission → show request screen
    if (!provider.hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Require Permission",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "We need your permission to load photos from your device.",
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () => provider.requestPermission(),
                child: Text("Grant Access"),
              ),
            ],
          ),
        ),
      );
    }

    // If permission granted → show gallery
    return Scaffold(
      appBar: AppBar(title: Text("Photos"),centerTitle: true,),
      body: Stack(
        children: [
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: provider.images.length,
            itemBuilder: (context, index) {
              final image = provider.images[index];
              final isSelected = provider.selected.contains(index);

              return GestureDetector(
                onTap: () => provider.toggleSelection(index),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(image, fit: BoxFit.cover),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(color: Colors.black26),
                        ),
                      ),
                    if (isSelected)
                      Center(
                        child: Icon(Icons.check_circle,
                            color: Colors.green, size: 30),
                      ),
                  ],
                ),
              );
            },
          ),
          if (provider.isLoading)
            Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: provider.selected.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: provider.saveSelected,
        label: Text("Download"),
        icon: Icon(Icons.download),
      )
          : null,
    );
  }
}
