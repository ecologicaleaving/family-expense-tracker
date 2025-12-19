import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/scan_result_entity.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../datasources/scanner_remote_datasource.dart';

/// Implementation of [ScannerRepository] using remote data source.
class ScannerRepositoryImpl implements ScannerRepository {
  ScannerRepositoryImpl({required this.remoteDataSource});

  final ScannerRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, ScanResultEntity>> scanReceipt({
    required Uint8List imageData,
  }) async {
    try {
      final result = await remoteDataSource.scanReceipt(imageData: imageData);
      return Right(result.toEntity());
    } on ScanException catch (e) {
      return Left(ScanFailure(e.message));
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScanResultEntity>> scanReceiptBase64({
    required String base64Image,
  }) async {
    try {
      final result = await remoteDataSource.scanReceiptBase64(base64Image: base64Image);
      return Right(result.toEntity());
    } on ScanException catch (e) {
      return Left(ScanFailure(e.message));
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
