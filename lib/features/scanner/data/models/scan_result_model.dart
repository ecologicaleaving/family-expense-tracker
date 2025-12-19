import '../../domain/entities/scan_result_entity.dart';

/// Scan result model for JSON serialization/deserialization.
///
/// Maps to the response from the scan-receipt Edge Function.
class ScanResultModel extends ScanResultEntity {
  const ScanResultModel({
    super.amount,
    super.date,
    super.merchant,
    required super.confidence,
    super.rawText,
  });

  /// Create a ScanResultModel from a JSON map (Edge Function response).
  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'] as String);
      } catch (_) {
        date = null;
      }
    }

    return ScanResultModel(
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      date: date,
      merchant: json['merchant'] as String?,
      confidence: json['confidence'] as int? ?? 0,
      rawText: json['rawText'] as String?,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date?.toIso8601String().split('T')[0],
      'merchant': merchant,
      'confidence': confidence,
      'rawText': rawText,
    };
  }

  /// Create a ScanResultModel from a ScanResultEntity.
  factory ScanResultModel.fromEntity(ScanResultEntity entity) {
    return ScanResultModel(
      amount: entity.amount,
      date: entity.date,
      merchant: entity.merchant,
      confidence: entity.confidence,
      rawText: entity.rawText,
    );
  }

  /// Convert to ScanResultEntity.
  ScanResultEntity toEntity() {
    return ScanResultEntity(
      amount: amount,
      date: date,
      merchant: merchant,
      confidence: confidence,
      rawText: rawText,
    );
  }

  /// Create a copy with updated fields.
  @override
  ScanResultModel copyWith({
    double? amount,
    DateTime? date,
    String? merchant,
    int? confidence,
    String? rawText,
  }) {
    return ScanResultModel(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }

  /// Create an empty model.
  factory ScanResultModel.empty() {
    return const ScanResultModel(confidence: 0);
  }
}
