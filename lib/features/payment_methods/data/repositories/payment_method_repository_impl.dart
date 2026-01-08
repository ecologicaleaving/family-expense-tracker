import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../datasources/payment_method_remote_datasource.dart';

/// Implementation of PaymentMethodRepository.
///
/// Currently uses remote datasource only.
/// TODO: Add cache datasource for offline support (Phase 7).
class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  PaymentMethodRepositoryImpl({
    required PaymentMethodRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PaymentMethodRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods({
    required String userId,
  }) async {
    try {
      final paymentMethods = await _remoteDataSource.getPaymentMethods(
        userId: userId,
        includeExpenseCount: true,
      );
      return Right(paymentMethods);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethodEntity>> getPaymentMethodById({
    required String id,
  }) async {
    try {
      final paymentMethod = await _remoteDataSource.getPaymentMethod(id: id);
      return Right(paymentMethod);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethodEntity>> createPaymentMethod({
    required String userId,
    required String name,
  }) async {
    try {
      // Validate name
      final trimmedName = name.trim();
      if (trimmedName.isEmpty || trimmedName.length > 50) {
        return const Left(
          ValidationFailure('Payment method name must be 1-50 characters'),
        );
      }

      final paymentMethod = await _remoteDataSource.createPaymentMethod(
        userId: userId,
        name: trimmedName,
      );
      return Right(paymentMethod);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethodEntity>> updatePaymentMethod({
    required String id,
    required String name,
  }) async {
    try {
      // Validate name
      final trimmedName = name.trim();
      if (trimmedName.isEmpty || trimmedName.length > 50) {
        return const Left(
          ValidationFailure('Payment method name must be 1-50 characters'),
        );
      }

      final paymentMethod = await _remoteDataSource.updatePaymentMethod(
        id: id,
        name: trimmedName,
      );
      return Right(paymentMethod);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePaymentMethod({
    required String id,
  }) async {
    try {
      await _remoteDataSource.deletePaymentMethod(id: id);
      return const Right(true);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getPaymentMethodExpenseCount({
    required String id,
  }) async {
    try {
      final count =
          await _remoteDataSource.getPaymentMethodExpenseCount(id: id);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,
  }) async {
    try {
      final exists = await _remoteDataSource.paymentMethodNameExists(
        userId: userId,
        name: name,
        excludeId: excludeId,
      );
      return Right(exists);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Stream<List<PaymentMethodEntity>> watchPaymentMethods({
    required String userId,
  }) {
    // TODO: Implement real-time subscription using Supabase Realtime
    // For now, return empty stream
    throw UnimplementedError(
      'Real-time payment method watching not yet implemented',
    );
  }

  @override
  Future<Either<Failure, PaymentMethodEntity>> getDefaultContanti() async {
    try {
      final paymentMethod = await _remoteDataSource.getDefaultContanti();
      return Right(paymentMethod);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
