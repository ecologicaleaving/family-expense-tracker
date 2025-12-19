import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

/// Service for camera and image picking operations.
class CameraService {
  CameraService._();

  static final ImagePicker _picker = ImagePicker();
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;

  /// Initialize available cameras.
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _cameras = [];
    }
  }

  /// Get list of available cameras.
  static List<CameraDescription> get cameras => _cameras ?? [];

  /// Check if camera is available.
  static bool get hasCameras => cameras.isNotEmpty;

  /// Get the back camera (preferred for scanning).
  static CameraDescription? get backCamera {
    if (!hasCameras) return null;
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  /// Get the front camera.
  static CameraDescription? get frontCamera {
    if (!hasCameras) return null;
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  /// Create a camera controller.
  static Future<CameraController?> createController({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    final selectedCamera = camera ?? backCamera;
    if (selectedCamera == null) return null;

    _controller = CameraController(
      selectedCamera,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      return _controller;
    } catch (e) {
      _controller = null;
      return null;
    }
  }

  /// Get the current camera controller.
  static CameraController? get controller => _controller;

  /// Dispose the camera controller.
  static Future<void> disposeController() async {
    await _controller?.dispose();
    _controller = null;
  }

  /// Take a picture with the current camera.
  static Future<Uint8List?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final file = await _controller!.takePicture();
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from the gallery.
  static Future<Uint8List?> pickFromGallery({
    int maxWidth = 1200,
    int maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;
      return await pickedFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Take a picture using the system camera app.
  static Future<Uint8List?> captureWithSystemCamera({
    int maxWidth = 1200,
    int maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) return null;
      return await pickedFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Toggle flash mode.
  static Future<FlashMode?> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final currentMode = _controller!.value.flashMode;
      final newMode = currentMode == FlashMode.off
          ? FlashMode.auto
          : currentMode == FlashMode.auto
              ? FlashMode.always
              : FlashMode.off;

      await _controller!.setFlashMode(newMode);
      return newMode;
    } catch (e) {
      return null;
    }
  }

  /// Set focus point.
  static Future<void> setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
    } catch (e) {
      // Ignore focus errors
    }
  }
}
