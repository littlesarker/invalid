import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invalidco/provider/splashProvider.dart';
import 'package:invalidco/views/splashScreen.dart';
import 'package:provider/provider.dart';
import 'views/gallery_page.dart';
import 'provider/gallery_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
      ],
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
      home: AppWrapper(), // Changed from GalleryPage to AppWrapper
    );
  }
}

// App Wrapper to handle splash screen and initialization
class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize splash screen after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final splashProvider = Provider.of<SplashProvider>(context, listen: false);
      splashProvider.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashProvider>(
      builder: (context, splashProvider, child) {
        // Show splash screen until initialization is complete
        if (splashProvider.showSplash) {
          return const SplashScreen();
        }

        // Initialize gallery provider after splash is done
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
          if (!galleryProvider.isInitialized) {
            galleryProvider.initialize();
          }
        });

        // Return your main gallery page
        return  GalleryPage();
      },
    );
  }
}