import 'package:flutter/cupertino.dart';
// providers/splash_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class SplashProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _showSplash = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get showSplash => _showSplash;
  String? get errorMessage => _errorMessage;

  // Simulate initialization process
  Future<void> initializeApp() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate some initialization tasks
      await Future.wait([
        _loadConfigurations(),
        _initializeServices(),
        _checkFirstLaunch(),
      ]);

      // Wait for minimum splash time (2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      _isLoading = false;
      notifyListeners();

      // Keep splash visible for a smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      _showSplash = false;
      notifyListeners();

    } catch (e) {
      _errorMessage = "Failed to initialize app: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadConfigurations() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _initializeServices() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void hideSplash() {
    _showSplash = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}