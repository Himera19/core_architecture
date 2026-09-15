library;

// ==================== Core Architecture ====================
// Re-exported so a single import is enough:
//   import 'package:core_architecture_supabase/core_architecture_supabase.dart';
export 'package:core_architecture/core_architecture.dart';

// ==================== Supabase Backend ====================
export 'src/supabase/supabase_core_extension.dart';
export 'src/supabase/supabase_service.dart';
export 'src/supabase/supabase_crud_client.dart';
export 'src/supabase/supabase_providers.dart';

// Re-export Supabase Flutter for convenience.
// This gives you access to User, AuthState, AuthException, PostgrestException,
// etc. Nothing is hidden: core_architecture deliberately avoids the SDK's type
// names (its own are AuthenticationException / LocalStorageException), so
// `on AuthException` here always means what the SDK throws.
export 'package:supabase_flutter/supabase_flutter.dart';
