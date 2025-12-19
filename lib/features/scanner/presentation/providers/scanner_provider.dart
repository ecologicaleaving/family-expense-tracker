import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/services/image_compression_service.dart';
import '../../data/datasources/scanner_remote_datasource.dart';
import '../../data/repositories/scanner_repository_impl.dart';
import '../../domain/entities/scan_result_entity.dart';
import '../../domain/repositories/scanner_repository.dart';

/// Provider for scanner remote data source
final scannerRemoteDataSourceProvider = Provider<ScannerRemoteDataSource>((ref) {
  return ScannerRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

/// Provider for scanner repository
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepositoryImpl(
    remoteDataSource: ref.watch(scannerRemoteDataSourceProvider),
  );
});

/// Scanner state status
enum ScannerStatus {
  initial,
  capturing,
  processing,
  success,
  error,
}

/// Scanner state class
class ScannerState {
  const ScannerState({
    this.status = ScannerStatus.initial,
    this.capturedImage,
    this.scanResult,
    this.errorMessage,
  });

  final ScannerStatus status;
  final Uint8List? capturedImage;
  final ScanResultEntity? scanResult;
  final String? errorMessage;

  ScannerState copyWith({
    ScannerStatus? status,
    Uint8List? capturedImage,
    ScanResultEntity? scanResult,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      capturedImage: capturedImage ?? this.capturedImage,
      scanResult: scanResult ?? this.scanResult,
      errorMessage: errorMessage,
    );
  }

  bool get isCapturing => status == ScannerStatus.capturing;
  bool get isProcessing => status == ScannerStatus.processing;
  bool get isSuccess => status == ScannerStatus.success;
  bool get hasError => status == ScannerStatus.error;
  bool get hasCapturedImage => capturedImage != null;
  bool get hasScanResult => scanResult != null;
}

/// Scanner notifier for managing scan state
class ScannerNotifier extends StateNotifier<ScannerState> {
  ScannerNotifier(this._scannerRepository) : super(const ScannerState());

  final ScannerRepository _scannerRepository;

  /// Set captured image
  void setCapturedImage(Uint8List imageData) {
    state = state.copyWith(
      status: ScannerStatus.capturing,
      capturedImage: imageData,
    );
  }

  /// Clear captured image
  void clearCapturedImage() {
    state = const ScannerState();
  }

  /// Scan the captured image
  Future<void> scanImage() async {
    if (state.capturedImage == null) {
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Nessuna immagine da analizzare',
      );
      return;
    }

    state = state.copyWith(status: ScannerStatus.processing, errorMessage: null);

    // Compress image for scanning
    final compressedImage = await ImageCompressionService.compressForScanning(
      state.capturedImage!,
    );

    final result = await _scannerRepository.scanReceipt(imageData: compressedImage);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ScannerStatus.error,
          errorMessage: failure.message,
        );
      },
      (scanResult) {
        state = state.copyWith(
          status: ScannerStatus.success,
          scanResult: scanResult,
        );
      },
    );
  }

  /// Retry scanning
  Future<void> retryScan() async {
    if (state.capturedImage != null) {
      await scanImage();
    }
  }

  /// Update scan result manually
  void updateScanResult({
    double? amount,
    DateTime? date,
    String? merchant,
  }) {
    if (state.scanResult == null) return;

    state = state.copyWith(
      scanResult: state.scanResult!.copyWith(
        amount: amount,
        date: date,
        merchant: merchant,
      ),
    );
  }

  /// Reset scanner state
  void reset() {
    state = const ScannerState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for scanner state
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier(ref.watch(scannerRepositoryProvider));
});
