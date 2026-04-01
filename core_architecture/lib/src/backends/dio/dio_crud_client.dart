// lib/src/backends/dio/dio_crud_client.dart

import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/logger_service.dart';
import '../contracts/crud_contract.dart';
import 'dio_service.dart';

/// Dio/REST API implementation of CrudContract
///
/// Provides CRUD operations using REST API as the backend.
/// Auth operations are also handled as CRUD operations (e.g., POST /auth/login).
/// Automatically handles logging and error conversion.
class DioCrudClient implements CrudContract {
  final DioService _dio;
  final LoggerService _logger;

  DioCrudClient({
    required DioService dio,
    LoggerService? logger,
  })  : _dio = dio,
        _logger = logger ?? LoggerService();

  @override
  Future<List<T>> query<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    String columns = '*',
    Map<String, dynamic>? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      _logger.d('Querying: GET /$table', tag: 'DioCRUD');

      // Build query parameters
      final queryParams = <String, dynamic>{};

      if (filter != null) {
        queryParams.addAll(filter);
      }
      if (orderBy != null) {
        queryParams['order_by'] = orderBy;
        queryParams['ascending'] = ascending;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      if (offset != null) {
        queryParams['offset'] = offset;
      }
      if (columns != '*') {
        queryParams['fields'] = columns;
      }

      final response = await _dio.get(
        '/$table',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final results = data
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d('Query successful. Count: ${results.length}', tag: 'DioCRUD');
      return results;
    } on DioException catch (e) {
      _logger.e('Query failed: /$table', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Query failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<T> getById<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d('Getting by ID: GET /$table/$id', tag: 'DioCRUD');

      final response = await _dio.get('/$table/$id');

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);

      final result = fromJson(data);
      _logger.d('GetById successful', tag: 'DioCRUD');
      return result;
    } on DioException catch (e) {
      _logger.e('GetById failed: /$table/$id', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'GetById failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<T> insert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      _logger.d('Inserting: POST /$table', tag: 'DioCRUD');

      final response = await _dio.post('/$table', data: data);

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);

      final result = fromJson(responseData);
      _logger.d('Insert successful', tag: 'DioCRUD');
      return result;
    } on DioException catch (e) {
      _logger.e('Insert failed: /$table', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Insert failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<T> update<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d('Updating: PUT /$table/$id', tag: 'DioCRUD');

      final response = await _dio.put('/$table/$id', data: data);

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);

      final result = fromJson(responseData);
      _logger.d('Update successful', tag: 'DioCRUD');
      return result;
    } on DioException catch (e) {
      _logger.e('Update failed: /$table/$id', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Update failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<void> delete({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d('Deleting: DELETE /$table/$id', tag: 'DioCRUD');

      await _dio.delete('/$table/$id');

      _logger.d('Delete successful', tag: 'DioCRUD');
    } on DioException catch (e) {
      _logger.e('Delete failed: /$table/$id', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Delete failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<List<T>> batchInsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      _logger.d(
        'Batch inserting ${data.length} records: POST /$table/batch',
        tag: 'DioCRUD',
      );

      final response = await _dio.post('/$table/batch', data: data);

      final List<dynamic> responseData = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final results = responseData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Batch insert successful. Count: ${results.length}',
        tag: 'DioCRUD',
      );
      return results;
    } on DioException catch (e) {
      _logger.e(
        'Batch insert failed: /$table/batch',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Batch insert failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<List<T>> batchUpdate<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d(
        'Batch updating ${data.length} records: PUT /$table/batch',
        tag: 'DioCRUD',
      );

      final response = await _dio.put('/$table/batch', data: data);

      final List<dynamic> responseData = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final results = responseData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Batch update successful. Count: ${results.length}',
        tag: 'DioCRUD',
      );
      return results;
    } on DioException catch (e) {
      _logger.e(
        'Batch update failed: /$table/batch',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Batch update failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<void> batchDelete({
    required String table,
    required List<String> ids,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d(
        'Batch deleting ${ids.length} records: DELETE /$table/batch',
        tag: 'DioCRUD',
      );

      await _dio.delete('/$table/batch', data: {idColumn: ids});

      _logger.d('Batch delete successful', tag: 'DioCRUD');
    } on DioException catch (e) {
      _logger.e(
        'Batch delete failed: /$table/batch',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Batch delete failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<bool> exists({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    try {
      _logger.d('Checking existence: HEAD /$table/$id', tag: 'DioCRUD');

      await _dio.get('/$table/$id');

      _logger.d('Exists check result: true', tag: 'DioCRUD');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.d('Exists check result: false', tag: 'DioCRUD');
        return false;
      }

      _logger.e(
        'Exists check failed: /$table/$id',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Exists check failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<T> upsert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  }) async {
    try {
      _logger.d('Upserting: POST /$table/upsert', tag: 'DioCRUD');

      final response = await _dio.post('/$table/upsert', data: data);

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data['data'] as Map<String, dynamic>);

      final result = fromJson(responseData);
      _logger.d('Upsert successful', tag: 'DioCRUD');
      return result;
    } on DioException catch (e) {
      _logger.e(
        'Upsert failed: /$table/upsert',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Upsert failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<List<T>> batchUpsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  }) async {
    try {
      _logger.d(
        'Batch upserting ${data.length} records: POST /$table/upsert/batch',
        tag: 'DioCRUD',
      );

      final response = await _dio.post('/$table/upsert/batch', data: data);

      final List<dynamic> responseData = response.data is List
          ? response.data as List
          : (response.data['data'] as List? ?? []);

      final results = responseData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Batch upsert successful. Count: ${results.length}',
        tag: 'DioCRUD',
      );
      return results;
    } on DioException catch (e) {
      _logger.e(
        'Batch upsert failed: /$table/upsert/batch',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Batch upsert failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<int> count({
    required String table,
    Map<String, dynamic>? filter,
  }) async {
    try {
      _logger.d('Counting: GET /$table/count', tag: 'DioCRUD');

      final response = await _dio.get(
        '/$table/count',
        queryParameters: filter,
      );

      final count = response.data is int
          ? response.data as int
          : (response.data['count'] as int? ?? 0);

      _logger.d('Count result: $count', tag: 'DioCRUD');
      return count;
    } on DioException catch (e) {
      _logger.e('Count failed: /$table/count', error: e.error, tag: 'DioCRUD');
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'Count failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<dynamic> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    try {
      _logger.d('Calling RPC: POST /rpc/$functionName', tag: 'DioCRUD');

      final response = await _dio.post('/rpc/$functionName', data: params);

      _logger.d('RPC successful', tag: 'DioCRUD');
      return response.data;
    } on DioException catch (e) {
      _logger.e(
        'RPC failed: /rpc/$functionName',
        error: e.error,
        tag: 'DioCRUD',
      );
      if (e.error is Failure) {
        throw e.error as Failure;
      }
      throw DatabaseFailure(message: e.message ?? 'RPC failed');
    } catch (e, st) {
      _logger.e('Unexpected error', error: e, stackTrace: st, tag: 'DioCRUD');
      throw DatabaseFailure(message: e.toString());
    }
  }



}
