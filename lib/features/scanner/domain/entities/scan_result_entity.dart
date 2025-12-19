import 'package:equatable/equatable.dart';

/// Scan result entity representing data extracted from a receipt.
class ScanResultEntity extends Equatable {
  const ScanResultEntity({
    this.amount,
    this.date,
    this.merchant,
    required this.confidence,
    this.rawText,
  });

  /// Extracted amount (null if not detected)
  final double? amount;

  /// Extracted date (null if not detected)
  final DateTime? date;

  /// Extracted merchant name (null if not detected)
  final String? merchant;

  /// Confidence score (0-100)
  final int confidence;

  /// Raw extracted text for debugging
  final String? rawText;

  /// Check if the scan was successful (at least amount was extracted)
  bool get isSuccessful => amount != null;

  /// Check if all fields were extracted
  bool get isComplete => amount != null && date != null && merchant != null;

  /// Check if confidence is high enough to auto-accept
  bool get isHighConfidence => confidence >= 70;

  /// Check if confidence is medium (needs review)
  bool get isMediumConfidence => confidence >= 40 && confidence < 70;

  /// Check if confidence is low (manual entry recommended)
  bool get isLowConfidence => confidence < 40;

  /// Create an empty result (for initial state or failure)
  factory ScanResultEntity.empty() {
    return const ScanResultEntity(
      confidence: 0,
    );
  }

  /// Create a failed result
  factory ScanResultEntity.failed() {
    return const ScanResultEntity(
      confidence: 0,
    );
  }

  /// Create a copy with updated fields
  ScanResultEntity copyWith({
    double? amount,
    DateTime? date,
    String? merchant,
    int? confidence,
    String? rawText,
  }) {
    return ScanResultEntity(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  List<Object?> get props => [amount, date, merchant, confidence, rawText];

  @override
  String toString() {
    return 'ScanResultEntity(amount: $amount, date: $date, merchant: $merchant, confidence: $confidence%)';
  }
}
