// lib/src/core/entities/base_entity.dart

/// Base class for all entities in the application.
///
/// Entities represent domain objects and business logic.
/// They are immutable and should not contain any serialization logic.
abstract class BaseEntity {
  const BaseEntity({required this.id});

  final String id;

  /// Subclasses must implement copyWith to support immutable updates.
  BaseEntity copyWith();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType(id: $id)';
}
