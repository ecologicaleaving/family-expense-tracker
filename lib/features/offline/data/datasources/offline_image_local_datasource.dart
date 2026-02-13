import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../local/offline_database.dart';
import '../models/offline_expense_image_model.dart';

/// T109: Local data source for offline receipt images
///
/// Features:
/// - Image compression (flutter_image_compress)
/// - 10MB max file size enforcement (FR-013)
/// - Local storage management
/// - Upload tracking
abstract class OfflineImageLocalDataSource {
  Future<OfflineExpenseImage> saveOfflineReceiptImage({
    required String expenseId,
    required String userId,
    required String imagePath,
  });

  Future<OfflineExpenseImage?> getOfflineReceiptImage(String expenseId);
  Future<List<OfflineExpenseImage>> getPendingUploads(String userId);
  Future<void> markAsUploaded(int imageId, String remoteUrl);
  Future<void> deleteOfflineImage(int imageId);
}

/// Implementation of OfflineImageLocalDataSource
class OfflineImageLocalDataSourceImpl implements OfflineImageLocalDataSource {
  final OfflineDatabase _db;
  final Uuid _uuid;

  // Constants
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int compressionQuality = 85; // 85% quality

  OfflineImageLocalDataSourceImpl({
    required OfflineDatabase database,
    required Uuid uuid,
  })  : _db = database,
        _uuid = uuid;

  @override
  Future<OfflineExpenseImage> saveOfflineReceiptImage({
    required String expenseId,
    required String userId,
    required String imagePath,
  }) async {
    // T111: Compress image
    final compressedPath = await _compressImage(imagePath);

    // T112: Check file size
    final file = File(compressedPath);
    final fileSize = await file.length();

    if (fileSize > maxFileSizeBytes) {
      throw Exception(
        'Image size (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB) '
        'exceeds maximum allowed size of 10 MB',
      );
    }

    // Move to app documents directory
    final localPath = await _moveToDocuments(compressedPath, expenseId);

    // Save to database
    final companion = OfflineExpenseImageModel.toCompanion(
      expenseId: expenseId,
      userId: userId,
      localPath: localPath,
      fileSizeBytes: fileSize,
    );

    final id = await _db.into(_db.offlineExpenseImages).insert(companion);

    // Return created image
    return await (_db.select(_db.offlineExpenseImages)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  @override
  Future<OfflineExpenseImage?> getOfflineReceiptImage(String expenseId) async {
    return await (_db.select(_db.offlineExpenseImages)
          ..where((tbl) => tbl.expenseId.equals(expenseId))
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<List<OfflineExpenseImage>> getPendingUploads(String userId) async {
    return await (_db.select(_db.offlineExpenseImages)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.uploaded.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.localCreatedAt),
          ]))
        .get();
  }

  @override
  Future<void> markAsUploaded(int imageId, String remoteUrl) async {
    final companion = OfflineExpenseImageModel.markUploaded(
      imageId: imageId,
      remoteUrl: remoteUrl,
    );

    await (_db.update(_db.offlineExpenseImages)
          ..where((tbl) => tbl.id.equals(imageId)))
        .write(companion);
  }

  @override
  Future<void> deleteOfflineImage(int imageId) async {
    // Get image to delete file
    final image = await (_db.select(_db.offlineExpenseImages)
          ..where((tbl) => tbl.id.equals(imageId)))
        .getSingleOrNull();

    if (image != null) {
      // Delete physical file
      final file = File(image.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete from database
      await (_db.delete(_db.offlineExpenseImages)
            ..where((tbl) => tbl.id.equals(imageId)))
          .go();
    }
  }

  /// T111: Compress image to reduce file size
  Future<String> _compressImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      'compressed_${_uuid.v4()}.jpg',
    );

    // Compress image
    final result = await FlutterImageCompress.compressAndGetFile(
      imagePath,
      targetPath,
      quality: compressionQuality,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Failed to compress image');
    }

    return result.path;
  }

  /// Move compressed image to app documents directory
  Future<String> _moveToDocuments(String sourcePath, String expenseId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(path.join(docsDir.path, 'receipts'));

    // Create receipts directory if it doesn't exist
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    // Generate unique filename
    final filename = '${expenseId}_${_uuid.v4()}.jpg';
    final targetPath = path.join(receiptsDir.path, filename);

    // Move file
    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    await sourceFile.delete(); // Clean up temp file

    return targetPath;
  }
}
