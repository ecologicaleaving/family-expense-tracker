import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Service for file picking operations (PDF and images).
class FilePickerService {
  FilePickerService._();

  /// Maximum file size in bytes (5MB).
  static const int maxFileSizeBytes = 5242880;

  /// Allowed file extensions.
  static const List<String> allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

  /// Pick a file (PDF or image) from device.
  ///
  /// Returns a record with file bytes, filename, and MIME type.
  /// Returns null values if user cancels or an error occurs.
  static Future<({Uint8List? bytes, String? filename, String? mimeType})>
      pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true, // Critical for web - ensures bytes are loaded
      );

      if (result == null || result.files.isEmpty) {
        return (bytes: null, filename: null, mimeType: null);
      }

      final file = result.files.first;
      return (
        bytes: file.bytes,
        filename: file.name,
        mimeType: _getMimeType(file.extension),
      );
    } catch (e) {
      return (bytes: null, filename: null, mimeType: null);
    }
  }

  /// Validate file size against maximum limit.
  ///
  /// Returns true if file size is valid (under 5MB), false otherwise.
  static bool validateFileSize(Uint8List? bytes) {
    if (bytes == null) return false;
    return bytes.length <= maxFileSizeBytes;
  }

  /// Get file size in megabytes.
  static double getFileSizeMB(Uint8List? bytes) {
    if (bytes == null) return 0;
    return bytes.length / (1024 * 1024);
  }

  /// Check if file is a PDF based on MIME type.
  static bool isPdf(String? mimeType) {
    return mimeType == 'application/pdf';
  }

  /// Check if file is an image based on MIME type.
  static bool isImage(String? mimeType) {
    return mimeType == 'image/png' ||
        mimeType == 'image/jpeg' ||
        mimeType == 'image/jpg';
  }

  /// Get MIME type from file extension.
  static String? _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return null;
    }
  }
}
