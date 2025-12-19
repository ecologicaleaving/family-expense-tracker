import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/scan_result_entity.dart';

/// Abstract scanner repository interface.
///
/// Defines the contract for receipt scanning operations.
/// Implementations should handle communication with the
/// scan-receipt Edge Function.
abstract class ScannerRepository {
  /// Scan a receipt image and extract data.
  ///
  /// Takes the image data and returns extracted information.
  /// The image should be compressed before sending.
  Future<Either<Failure, ScanResultEntity>> scanReceipt({
    required Uint8List imageData,
  });

  /// Scan a receipt from a base64 encoded image.
  Future<Either<Failure, ScanResultEntity>> scanReceiptBase64({
    required String base64Image,
  });
}
