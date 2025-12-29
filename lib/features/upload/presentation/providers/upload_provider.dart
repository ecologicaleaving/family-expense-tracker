import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/file_picker_service.dart';

/// Upload state status
enum UploadStatus {
  initial,
  picking,
  picked,
  uploading,
  success,
  error,
}

/// Upload state class for file upload flow
class UploadState {
  const UploadState({
    this.status = UploadStatus.initial,
    this.fileBytes,
    this.filename,
    this.mimeType,
    this.errorMessage,
  });

  final UploadStatus status;
  final Uint8List? fileBytes;
  final String? filename;
  final String? mimeType;
  final String? errorMessage;

  UploadState copyWith({
    UploadStatus? status,
    Uint8List? fileBytes,
    String? filename,
    String? mimeType,
    String? errorMessage,
  }) {
    return UploadState(
      status: status ?? this.status,
      fileBytes: fileBytes ?? this.fileBytes,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      errorMessage: errorMessage,
    );
  }

  /// Check if currently picking a file
  bool get isPicking => status == UploadStatus.picking;

  /// Check if a file has been picked
  bool get hasPicked => status == UploadStatus.picked;

  /// Check if currently uploading
  bool get isUploading => status == UploadStatus.uploading;

  /// Check if upload was successful
  bool get isSuccess => status == UploadStatus.success;

  /// Check if there's an error
  bool get hasError => status == UploadStatus.error;

  /// Check if file is a PDF based on MIME type
  bool get isPdf => FilePickerService.isPdf(mimeType);

  /// Check if file is an image based on MIME type
  bool get isImage => FilePickerService.isImage(mimeType);

  /// Check if a file is loaded
  bool get hasFile => fileBytes != null && filename != null;

  /// Get file size in MB
  double get fileSizeMB => FilePickerService.getFileSizeMB(fileBytes);
}

/// Upload notifier for managing file upload state
class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier() : super(const UploadState());

  /// Pick a file from device
  ///
  /// Opens the file picker and updates state with selected file.
  /// Validates file size (max 5MB) before accepting.
  Future<void> pickFile() async {
    state = state.copyWith(
      status: UploadStatus.picking,
      errorMessage: null,
    );

    final result = await FilePickerService.pickFile();

    // User cancelled or error occurred
    if (result.bytes == null) {
      state = state.copyWith(status: UploadStatus.initial);
      return;
    }

    // Validate file size
    if (!FilePickerService.validateFileSize(result.bytes)) {
      final sizeMB = FilePickerService.getFileSizeMB(result.bytes);
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage:
            'File troppo grande (${sizeMB.toStringAsFixed(1)} MB). Massimo 5 MB.',
      );
      return;
    }

    state = state.copyWith(
      status: UploadStatus.picked,
      fileBytes: result.bytes,
      filename: result.filename,
      mimeType: result.mimeType,
    );
  }

  /// Validate the current file
  ///
  /// Returns true if file is valid (exists and under size limit).
  bool validateFile() {
    if (state.fileBytes == null) return false;
    return FilePickerService.validateFileSize(state.fileBytes);
  }

  /// Set uploading status
  ///
  /// Call this when starting the upload process.
  void setUploading() {
    state = state.copyWith(
      status: UploadStatus.uploading,
      errorMessage: null,
    );
  }

  /// Set success status
  ///
  /// Call this when upload completes successfully.
  void setSuccess() {
    state = state.copyWith(status: UploadStatus.success);
  }

  /// Set error status with message
  ///
  /// Call this when upload fails.
  void setError(String message) {
    state = state.copyWith(
      status: UploadStatus.error,
      errorMessage: message,
    );
  }

  /// Clear the selected file and reset state
  void clearFile() {
    state = const UploadState();
  }

  /// Clear error message only
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for upload state
final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier();
});
