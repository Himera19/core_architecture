library;

// ==================== Core Architecture ====================
// Re-exported so a single import is enough:
//   import 'package:core_architecture_dio/core_architecture_dio.dart';
export 'package:core_architecture/core_architecture.dart';

// ==================== Dio Backend ====================
export 'src/dio/dio_core_extension.dart';
export 'src/dio/dio_service.dart';
export 'src/dio/dio_crud_client.dart';
export 'src/dio/dio_providers.dart';

// Re-export Dio for convenience.
export 'package:dio/dio.dart';
