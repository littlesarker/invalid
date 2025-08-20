import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class GalleryProvider with ChangeNotifier {
  static const platform = MethodChannel('gallery_channel');

  List<Uint8List> _images = [];
  Set<int> _selected = {};
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  List<Uint8List> get images => _images;
  Set<int> get selected => _selected;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  GalleryProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkPermission();
  }

  /// Check current permission status
  Future<void> checkPermission() async {
    try {
      final bool? granted = await platform.invokeMethod('checkPermission');
      _hasPermission = granted ?? false;
      notifyListeners();

      if (_hasPermission) {
        await loadImages();
      }
    } on PlatformException catch (e) {
      _handleError("Permission check failed: ${e.message}");
    } catch (e) {
      _handleError("Unexpected error during permission check: $e");
    }
  }

  /// Request permission from native side
  Future<void> requestPermission() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await platform.invokeMethod('requestPermission');

      // Wait a moment for the permission dialog to complete
      await Future.delayed(Duration(milliseconds: 500));

      // Check the new permission status
      await checkPermission();

    } on PlatformException catch (e) {
      _handleError("Permission request failed: ${e.message}");
    } catch (e) {
      _handleError("Unexpected error during permission request: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load images from gallery
  Future<void> loadImages() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final List<dynamic>? result = await platform.invokeMethod('getImages');

      if (result != null) {
        _images = result.whereType<Uint8List>().toList();
      } else {
        _images = [];
      }

    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        _hasPermission = false;
        _handleError("Storage permission denied. Please grant permission to access gallery.");
      } else {
        _handleError("Failed to load images: ${e.message}");
      }
    } catch (e) {
      _handleError("Unexpected error loading images: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelection(int index) {
    if (index >= 0 && index < _images.length) {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
      notifyListeners();
    }
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<bool> saveSelected() async {
    if (_selected.isEmpty) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      int successCount = 0;

      for (int index in _selected) {
        if (index >= 0 && index < _images.length) {
          final bool? result = await platform.invokeMethod('saveImage', {
            'bytes': _images[index],
          });

          if (result == true) {
            successCount++;
          }
        }
      }

      final bool allSaved = successCount == _selected.length;

      if (!allSaved) {
        _handleError("Failed to save some images. $successCount out of ${_selected.length} saved successfully.");
      }

      return allSaved;

    } on PlatformException catch (e) {
      _handleError("Failed to save images: ${e.message}");
      return false;
    } catch (e) {
      _handleError("Unexpected error saving images: $e");
      return false;
    } finally {
      _isLoading = false;
      _selected.clear();
      notifyListeners();
    }
  }

  void _handleError(String message) {
    _errorMessage = message;
    if (kDebugMode) {
      print("GalleryProvider Error: $message");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh gallery
  Future<void> refresh() async {
    if (_hasPermission) {
      await loadImages();
    } else {
      await checkPermission();
    }
  }
}