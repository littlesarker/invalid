
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
  bool _isInitialized = false;

  List<Uint8List> get images => _images;
  Set<int> get selected => _selected;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  /// Initialize gallery provider (replaces loadImages)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      await checkPermission();

      // Only load images if we have permission
      if (_hasPermission) {
        await _loadImages();
      }

      _isInitialized = true;

    } catch (e) {
      _handleError("Initialization failed: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check permission status
  Future<void> checkPermission() async {
    try {
      final bool? granted = await platform.invokeMethod('checkPermission');
      _hasPermission = granted ?? false;
      notifyListeners();
    } on PlatformException catch (e) {
      _handleError("Permission check failed: ${e.message}");
    } catch (e) {
      _handleError("Unexpected error during permission check: $e");
    }
  }

  /// Load images from gallery
  Future<void> _loadImages() async {
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

      // Load images if permission was granted
      if (_hasPermission) {
        await _loadImages();
      }

    } on PlatformException catch (e) {
      _handleError("Permission request failed: ${e.message}");
    } catch (e) {
      _handleError("Unexpected error during permission request: $e");
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
      await _loadImages();
    } else {
      await checkPermission();
    }
  }
}