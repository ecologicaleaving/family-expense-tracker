import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/scan_result_model.dart';

/// Remote data source for receipt scanning operations.
abstract class ScannerRemoteDataSource {
  /// Scan a receipt image and extract data.
  Future<ScanResultModel> scanReceipt({required Uint8List imageData});

  /// Scan a receipt from base64 encoded image.
  Future<ScanResultModel> scanReceiptBase64({required String base64Image});
}

/// Implementation of [ScannerRemoteDataSource] using Supabase Edge Functions.
class ScannerRemoteDataSourceImpl implements ScannerRemoteDataSource {
  ScannerRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  @override
  Future<ScanResultModel> scanReceipt({required Uint8List imageData}) async {
    // Convert to base64
    final base64Image = base64Encode(imageData);
    return scanReceiptBase64(base64Image: base64Image);
  }

  @override
  Future<ScanResultModel> scanReceiptBase64({required String base64Image}) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'scan-receipt',
        body: {'image': base64Image},
      );

      if (response.status != 200) {
        final error = response.data as Map<String, dynamic>?;
        final errorMessage = error?['error'] as String? ?? 'Errore durante la scansione';
        final errorCode = error?['code'] as String? ?? 'scan_error';

        throw ScanException(_mapErrorMessage(errorMessage), errorCode);
      }

      final data = response.data as Map<String, dynamic>;
      return ScanResultModel.fromJson(data);
    } on FunctionException catch (e) {
      throw ScanException(_mapErrorMessage(e.toString()), 'function_error');
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Errore durante la scansione dello scontrino', 'unknown_error');
    }
  }

  String _mapErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('no text detected')) {
      return 'Nessun testo rilevato. Assicurati che lo scontrino sia ben illuminato e a fuoco.';
    }
    if (lowerMessage.contains('api key')) {
      return 'Servizio di scansione non configurato correttamente.';
    }
    if (lowerMessage.contains('image')) {
      return 'Immagine non valida. Riprova con una foto diversa.';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Errore di connessione. Controlla la tua rete.';
    }

    return 'Errore durante la scansione. Riprova o inserisci i dati manualmente.';
  }
}
