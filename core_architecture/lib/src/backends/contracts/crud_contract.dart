// lib/src/backends/contracts/crud_contract.dart

/// Contract that all CRUD clients must implement
/// 
/// This interface defines standard Create, Read, Update, Delete operations
/// that should be available regardless of the backend (Supabase, REST API, etc.)
abstract class CrudContract {
  /// Query records from a table/endpoint with optional filtering, ordering, and pagination
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [fromJson] - Function to convert JSON to type [T]
  /// [columns] - Columns to select (Supabase) or fields to include (REST API)
  /// [filter] - Filter conditions as key-value pairs
  /// [orderBy] - Field to order by
  /// [ascending] - Sort direction (true = ascending, false = descending)
  /// [limit] - Maximum number of records to return
  /// [offset] - Number of records to skip (for pagination)
  /// 
  /// Returns a list of records of type [T]
  Future<List<T>> query<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    String columns = '*',
    Map<String, dynamic>? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  });

  /// Get a single record by ID
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [id] - The ID of the record to retrieve
  /// [fromJson] - Function to convert JSON to type [T]
  /// [idColumn] - Name of the ID column (default: 'id')
  /// 
  /// Returns the record of type [T]
  /// Throws [DatabaseFailure] if record not found
  Future<T> getById<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  });

  /// Insert a new record
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [data] - The data to insert as key-value pairs
  /// [fromJson] - Function to convert JSON response to type [T]
  /// 
  /// Returns the inserted record of type [T]
  Future<T> insert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// Update an existing record
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [id] - The ID of the record to update
  /// [data] - The data to update as key-value pairs
  /// [fromJson] - Function to convert JSON response to type [T]
  /// [idColumn] - Name of the ID column (default: 'id')
  /// 
  /// Returns the updated record of type [T]
  Future<T> update<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  });

  /// Delete a record
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [id] - The ID of the record to delete
  /// [idColumn] - Name of the ID column (default: 'id')
  Future<void> delete({
    required String table,
    required String id,
    String idColumn = 'id',
  });

  /// Insert multiple records in a single operation
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [data] - List of records to insert
  /// [fromJson] - Function to convert JSON to type [T]
  /// 
  /// Returns list of inserted records of type [T]
  Future<List<T>> batchInsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// Update multiple records in a single operation
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [data] - List of records to update (must include ID field)
  /// [fromJson] - Function to convert JSON to type [T]
  /// [idColumn] - Name of the ID column (default: 'id')
  /// 
  /// Returns list of updated records of type [T]
  Future<List<T>> batchUpdate<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  });

  /// Delete multiple records in a single operation
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [ids] - List of IDs to delete
  /// [idColumn] - Name of the ID column (default: 'id')
  Future<void> batchDelete({
    required String table,
    required List<String> ids,
    String idColumn = 'id',
  });

  /// Check if a record exists
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [id] - The ID to check
  /// [idColumn] - Name of the ID column (default: 'id')
  /// 
  /// Returns true if the record exists, false otherwise
  Future<bool> exists({
    required String table,
    required String id,
    String idColumn = 'id',
  });

  /// Upsert (insert or update) a record
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [data] - The data to upsert
  /// [fromJson] - Function to convert JSON to type [T]
  /// [onConflict] - Column(s) to check for conflicts (Supabase specific)
  /// 
  /// Returns the upserted record of type [T]
  Future<T> upsert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  });

  /// Upsert multiple records in a single operation
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [data] - List of records to upsert
  /// [fromJson] - Function to convert JSON to type [T]
  /// [onConflict] - Column(s) to check for conflicts (Supabase specific)
  /// 
  /// Returns list of upserted records of type [T]
  Future<List<T>> batchUpsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  });

  /// Count records in a table/endpoint
  /// 
  /// [table] - Table name (Supabase) or endpoint path (REST API)
  /// [filter] - Optional filter conditions
  /// 
  /// Returns the count of records
  Future<int> count({
    required String table,
    Map<String, dynamic>? filter,
  });

  /// Execute a Remote Procedure Call (RPC)
  ///
  /// [functionName] - Name of the function to call
  /// [params] - Parameters to pass to the function
  Future<void> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  });
}
