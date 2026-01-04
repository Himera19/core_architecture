library;

// Export core architecture
export 'core_architecture.dart';

// ==================== Supabase Backend ====================
export 'src/backends/supabase/supabase_service.dart';
export 'src/backends/supabase/supabase_crud_client.dart';
export 'src/backends/supabase/supabase_providers.dart';

// Re-export Supabase Flutter for convenience
// This gives you access to User, AuthState, etc.
export 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;
