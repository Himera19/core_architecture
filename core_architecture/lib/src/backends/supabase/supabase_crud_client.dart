// lib/src/backends/supabase/supabase_crud_client.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/logger_service.dart';
import '../contracts/crud_contract.dart';
import 'supabase_service.dart';

/// Supabase implementation of CrudContract
///
/// Provides complete CRUD operations using Supabase as the backend.
/// Supports queries with filtering, ordering, pagination, and batch operations.
/// Automatically handles logging and error conversion.
class SupabaseCrudClient implements CrudContract {
  final SupabaseService _supabase;
  final LoggerService _logger;

  SupabaseCrudClient({
    required SupabaseService supabase,
    LoggerService? logger,
  })  : _supabase = supabase,
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
      _logger.d('Querying table: $table', tag: 'SupabaseCRUD');

      // Start building the query
      dynamic query = _supabase.client.from(table).select(columns);

      // Apply filters
      if (filter != null) {
        for (final entry in filter.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 100) - 1);
      }

      // Execute query
      final List<dynamic> response = await query;

      // Parse results
      final results = response
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Query successful. Count: ${results.length}',
        tag: 'SupabaseCRUD',
      );
      return results;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Query failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Getting by ID: $table/$id', tag: 'SupabaseCRUD');

      final response = await _supabase.client
          .from(table)
          .select()
          .eq(idColumn, id)
          .single();

      final result = fromJson(response);
      _logger.d('GetById successful', tag: 'SupabaseCRUD');
      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'GetById failed. Table: $table, ID: $id',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Inserting into: $table', tag: 'SupabaseCRUD');

      final response = await _supabase.client
          .from(table)
          .insert(data)
          .select()
          .single();

      final result = fromJson(response);
      _logger.d('Insert successful', tag: 'SupabaseCRUD');
      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Insert failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Updating in: $table/$id', tag: 'SupabaseCRUD');

      final response = await _supabase.client
          .from(table)
          .update(data)
          .eq(idColumn, id)
          .select()
          .single();

      final result = fromJson(response);
      _logger.d('Update successful', tag: 'SupabaseCRUD');
      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Update failed. Table: $table, ID: $id',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Deleting from: $table/$id', tag: 'SupabaseCRUD');

      await _supabase.client.from(table).delete().eq(idColumn, id);

      _logger.d('Delete successful', tag: 'SupabaseCRUD');
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Delete failed. Table: $table, ID: $id',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
        'Batch inserting ${data.length} records into: $table',
        tag: 'SupabaseCRUD',
      );

      final response = await _supabase.client.from(table).insert(data).select();

      final results = (response as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Batch insert successful. Count: ${results.length}',
        tag: 'SupabaseCRUD',
      );
      return results;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Batch insert failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
        'Batch updating ${data.length} records in: $table',
        tag: 'SupabaseCRUD',
      );

      // Supabase doesn't have native batch update, so we do it individually
      // For better performance, consider using upsert instead
      final results = <T>[];

      for (final item in data) {
        final id = item[idColumn];
        if (id == null) {
          throw DatabaseFailure(
            message: 'Missing $idColumn in batch update item',
          );
        }

        final result = await update<T>(
          table: table,
          id: id.toString(),
          data: item,
          fromJson: fromJson,
          idColumn: idColumn,
        );
        results.add(result);
      }

      _logger.d(
        'Batch update successful. Count: ${results.length}',
        tag: 'SupabaseCRUD',
      );
      return results;
    } catch (e, st) {
      _logger.e(
        'Batch update failed',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      if (e is DatabaseFailure) rethrow;
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
        'Batch deleting ${ids.length} records from: $table',
        tag: 'SupabaseCRUD',
      );

      await _supabase.client.from(table).delete().inFilter(idColumn, ids);

      _logger.d('Batch delete successful', tag: 'SupabaseCRUD');
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Batch delete failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Checking existence: $table/$id', tag: 'SupabaseCRUD');

      final response = await _supabase.client
          .from(table)
          .select(idColumn)
          .eq(idColumn, id)
          .maybeSingle();

      final exists = response != null;
      _logger.d('Exists check result: $exists', tag: 'SupabaseCRUD');
      return exists;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Exists check failed. Table: $table, ID: $id',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
      _logger.d('Upserting in: $table', tag: 'SupabaseCRUD');

      var query = _supabase.client.from(table).upsert(data);

      final response = await query.select().single();
      final result = fromJson(response);

      _logger.d('Upsert successful', tag: 'SupabaseCRUD');
      return result;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Upsert failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
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
        'Batch upserting ${data.length} records in: $table',
        tag: 'SupabaseCRUD',
      );

      var query = _supabase.client.from(table).upsert(data);

      final response = await query.select();
      final results = (response as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Batch upsert successful. Count: ${results.length}',
        tag: 'SupabaseCRUD',
      );
      return results;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Batch upsert failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<int> count({
    required String table,
    Map<String, dynamic>? filter,
  }) async {
    try {
      var query = _supabase.client.from(table).select();

      if (filter != null && filter.isNotEmpty) {
        for (final entry in filter.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      final response = await query;
      return response.length;
    } catch (e) {
      throw DatabaseFailure(message: e.toString());
    }
  }

  @override
  Future<void> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    try {
      _logger.d('Calling RPC: $functionName', tag: 'SupabaseCRUD');

      await _supabase.client.rpc(functionName, params: params);

      _logger.d('RPC successful', tag: 'SupabaseCRUD');
    } on PostgrestException catch (e, st) {
      _logger.e(
        'RPC failed. Function: $functionName',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.toString());
    }
  }

  // ==================== Advanced Query Methods ====================

  /// Query with custom filter function
  ///
  /// Example:
  /// ```dart
  /// final todos = await crudClient.queryWithFilter<Todo>(
  ///   table: 'todos',
  ///   fromJson: (json) => TodoModel.fromJson(json),
  ///   filterBuilder: (query) => query
  ///       .eq('user_id', userId)
  ///       .gte('created_at', startDate)
  ///       .order('priority', ascending: false),
  /// );
  /// ```
  Future<List<T>> queryWithFilter<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    required PostgrestFilterBuilder Function(PostgrestFilterBuilder)
    filterBuilder,
    String columns = '*',
  }) async {
    try {
      _logger.d('Querying with custom filter: $table', tag: 'SupabaseCRUD');

      final baseQuery = _supabase.client.from(table).select(columns);
      final query = filterBuilder(baseQuery);
      final List<dynamic> response = await query;

      final results = response
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      _logger.d(
        'Query successful. Count: ${results.length}',
        tag: 'SupabaseCRUD',
      );
      return results;
    } on PostgrestException catch (e, st) {
      _logger.e(
        'Query with filter failed. Table: $table',
        error: e.message,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.message, code: e.code);
    } catch (e, st) {
      _logger.e(
        'Unexpected DB error',
        error: e,
        stackTrace: st,
        tag: 'SupabaseCRUD',
      );
      throw DatabaseFailure(message: e.toString());
    }
  }
}