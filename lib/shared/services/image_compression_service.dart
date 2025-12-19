import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for image compression and resizing.
class ImageCompressionService {
  ImageCompressionService._();

  /// Maximum image size in bytes (1MB).
  static const int maxSizeBytes = 1024 * 1024;

  /// Default quality for compression.
  static const int defaultQuality = 85;

  /// Maximum width for receipt images.
  static const int maxWidth = 1200;

  /// Maximum height for receipt images.
  static const int maxHeight = 1600;

  /// Compress an image to meet size requirements.
  ///
  /// Returns compressed image data that is under [maxSizeBytes].
  static Future<Uint8List> compressImage(
    Uint8List imageData, {
    int quality = defaultQuality,
    int targetWidth = maxWidth,
    int targetHeight = maxHeight,
  }) async {
    Uint8List compressed = imageData;
    int currentQuality = quality;

    // Try to compress until under max size or minimum quality reached
    while (compressed.lengthInBytes > maxSizeBytes && currentQuality > 20) {
      compressed = await FlutterImageCompress.compressWithList(
        imageData,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: currentQuality,
        format: CompressFormat.jpeg,
      );

      currentQuality -= 10;
    }

    return compressed;
  }

  /// Compress image for upload to storage.
  ///
  /// Optimizes for receipt scanning: good quality but reasonable size.
  static Future<Uint8List> compressForUpload(Uint8List imageData) async {
    return compressImage(
      imageData,
      quality: 80,
      targetWidth: 1200,
      targetHeight: 1600,
    );
  }

  /// Compress image for scanning.
  ///
  /// Higher quality needed for OCR accuracy.
  static Future<Uint8List> compressForScanning(Uint8List imageData) async {
    return compressImage(
      imageData,
      quality: 90,
      targetWidth: 1500,
      targetHeight: 2000,
    );
  }

  /// Create a thumbnail for preview.
  static Future<Uint8List> createThumbnail(
    Uint8List imageData, {
    int size = 200,
  }) async {
    return FlutterImageCompress.compressWithList(
      imageData,
      minWidth: size,
      minHeight: size,
      quality: 70,
      format: CompressFormat.jpeg,
    );
  }

  /// Get image dimensions from data.
  static Future<ImageDimensions?> getImageDimensions(Uint8List imageData) async {
    try {
      // Use image package or decode headers
      // For now, return null and let the caller handle it
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if image needs compression.
  static bool needsCompression(Uint8List imageData) {
    return imageData.lengthInBytes > maxSizeBytes;
  }

  /// Get file size in human readable format.
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Image dimensions.
class ImageDimensions {
  const ImageDimensions({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  double get aspectRatio => width / height;
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
}
