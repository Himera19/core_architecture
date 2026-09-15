import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../showcase/section.dart';

/// The backend-agnostic half of the package: [BaseEntity], the [Failure] and
/// [AppException] hierarchies, and [CrudContract] — implemented here by an
/// in-memory fake, which is the point of the contract.
class DomainScreen extends StatefulWidget {
  const DomainScreen({super.key});

  static const String path = '/domain';

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  final InMemoryCrud _crud = InMemoryCrud();

  List<Hobby> _rows = const [];
  String _lastCall = 'no call yet';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final List<Hobby> rows = await _crud.query<Hobby>(
      table: 'hobbies',
      fromJson: Hobby.fromJson,
      orderBy: 'name',
    );
    if (mounted) setState(() => _rows = rows);
  }

  Future<void> _call(String label, Future<Object?> Function() action) async {
    try {
      final Object? result = await action();
      if (!mounted) return;
      setState(() => _lastCall = '$label → $result');
      await _refresh();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _lastCall = '$label → ${e.runtimeType}: ${e.message}');
    }
  }

  /// Three entities, two of which BaseEntity treats as the same row.
  ///
  /// Compared here rather than inline in the widget tree: BaseEntity overrides
  /// `==`, and a const expression may only compare operands with primitive
  /// equality, so a const `Readout` around the comparison will not compile.
  static const Hobby _a = Hobby(id: '1', name: 'Climbing');
  static const Hobby _sameId = Hobby(id: '1', name: 'Bouldering');
  static const Hobby _otherId = Hobby(id: '2', name: 'Climbing');

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    final String matchesSameId = '${_a == _sameId}';
    final String matchesOtherId = '${_a == _otherId}';

    return ShowcasePage(
      title: 'Domain',
      sections: [
        Section(
          title: 'Entity identity',
          api: 'BaseEntity — equality and hashCode by id',
          children: [
            Readout('a', _a.toString()),
            Readout('a == b (same id, different name)', matchesSameId),
            Readout('a == c (different id)', matchesOtherId),
            Readout('copyWith(name:)', _a.copyWith(name: 'Surfing').name),
            Gap.hXs,
            Text(
              'Two entities with the same id are the same row, whatever else '
              'differs — which is what lets a list dedupe them.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'A CrudContract, backed by a Map',
          api: 'CrudContract — the interface a backend package implements',
          children: [
            for (final row in _rows)
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.id} · ${row.name}',
                        style: AppTypography.bodyMd,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: AppSizes.iconSm,
                      onPressed: () => _call('delete', () async {
                        await _crud.delete(table: 'hobbies', id: row.id);
                        return 'ok';
                      }),
                    ),
                  ],
                ),
              ),
            if (_rows.isEmpty)
              Text(
                'no rows',
                style: AppTypography.bodySm.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            Gap.hSm,
            Wrap(
              spacing: AppSpacings.wXs,
              runSpacing: AppSpacings.hXs,
              children: [
                ActionChip(
                  label: const Text('insert'),
                  onPressed: () => _call(
                    'insert',
                    () async => (await _crud.insert<Hobby>(
                      table: 'hobbies',
                      data: {
                        'id': '${_rows.length + 1}',
                        'name': 'Hobby ${_rows.length + 1}',
                      },
                      fromJson: Hobby.fromJson,
                    )).name,
                  ),
                ),
                ActionChip(
                  label: const Text('getById("1")'),
                  onPressed: () => _call(
                    'getById',
                    () async => (await _crud.getById<Hobby>(
                      table: 'hobbies',
                      id: '1',
                      fromJson: Hobby.fromJson,
                    )).name,
                  ),
                ),
                ActionChip(
                  label: const Text('getById("nope")'),
                  // Throws DatabaseException, caught and shown below.
                  onPressed: () => _call(
                    'getById',
                    () async => (await _crud.getById<Hobby>(
                      table: 'hobbies',
                      id: 'nope',
                      fromJson: Hobby.fromJson,
                    )).name,
                  ),
                ),
                ActionChip(
                  label: const Text('upsert'),
                  onPressed: () => _call(
                    'upsert',
                    () async => (await _crud.upsert<Hobby>(
                      table: 'hobbies',
                      data: const {'id': '1', 'name': 'Upserted'},
                      fromJson: Hobby.fromJson,
                    )).name,
                  ),
                ),
                ActionChip(
                  label: const Text('batchInsert'),
                  onPressed: () => _call(
                    'batchInsert',
                    () async => '${(await _crud.batchInsert<Hobby>(table: 'hobbies', data: const [
                      {'id': '8', 'name': 'Batch A'},
                      {'id': '9', 'name': 'Batch B'},
                    ], fromJson: Hobby.fromJson)).length} rows',
                  ),
                ),
                ActionChip(
                  label: const Text('update("1")'),
                  onPressed: () => _call(
                    'update',
                    () async => (await _crud.update<Hobby>(
                      table: 'hobbies',
                      id: '1',
                      data: const {'name': 'Updated'},
                      fromJson: Hobby.fromJson,
                    )).name,
                  ),
                ),
                ActionChip(
                  label: const Text('batchUpdate'),
                  onPressed: () => _call(
                    'batchUpdate',
                    () async => '${(await _crud.batchUpdate<Hobby>(table: 'hobbies', data: const [
                      {'id': '1', 'name': 'Batch updated'},
                      {'id': '2', 'name': 'Also updated'},
                    ], fromJson: Hobby.fromJson)).length} rows',
                  ),
                ),
                ActionChip(
                  label: const Text('batchUpsert'),
                  onPressed: () => _call(
                    'batchUpsert',
                    () async => '${(await _crud.batchUpsert<Hobby>(table: 'hobbies', data: const [
                      {'id': '2', 'name': 'Upserted too'},
                      {'id': '7', 'name': 'Brand new'},
                    ], fromJson: Hobby.fromJson)).length} rows',
                  ),
                ),
                ActionChip(
                  label: const Text('count'),
                  onPressed: () =>
                      _call('count', () => _crud.count(table: 'hobbies')),
                ),
                ActionChip(
                  label: const Text('exists("1")'),
                  onPressed: () => _call(
                    'exists',
                    () => _crud.exists(table: 'hobbies', id: '1'),
                  ),
                ),
                ActionChip(
                  label: const Text('rpc'),
                  onPressed: () => _call(
                    'rpc',
                    () => _crud.rpc(functionName: 'longest_name'),
                  ),
                ),
                ActionChip(
                  label: const Text('batchDelete'),
                  onPressed: () => _call('batchDelete', () async {
                    await _crud.batchDelete(
                      table: 'hobbies',
                      ids: const ['8', '9'],
                    );
                    return 'ok';
                  }),
                ),
              ],
            ),
            Gap.hSm,
            Readout('last call', _lastCall),
          ],
        ),

        Section(
          title: 'Failures — returned, not thrown',
          api: 'Failure and its subclasses',
          children: [
            for (final failure in const <Failure>[
              NetworkFailure(message: 'No connection'),
              ServerFailure(message: 'Bad gateway', code: '502'),
              TimeoutFailure(message: 'Timed out'),
              AuthFailure(message: 'Wrong password'),
              UnauthorizedFailure(message: 'Token expired', code: '401'),
              DatabaseFailure(message: 'Constraint violated'),
              ValidationFailure(message: 'Email is invalid'),
              StorageFailure(message: 'Disk full'),
              CacheFailure(message: 'Cache miss'),
              UnknownFailure(message: 'Something else'),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppSizes.thumbnailMd + AppSpacings.wXl,
                      child: Text(
                        '${failure.runtimeType}',
                        style: AppTypography.labelSm,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        failure.code == null
                            ? failure.message
                            : '${failure.message} (${failure.code})',
                        style: AppTypography.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        Section(
          title: 'Exceptions — thrown, then caught',
          api: 'AppException and its subclasses',
          children: [
            Wrap(
              spacing: AppSpacings.wXs,
              runSpacing: AppSpacings.hXs,
              children: [
                for (final exception in const <AppException>[
                  NetworkException(message: 'No connection'),
                  ServerException(message: 'Bad gateway', code: '502'),
                  RequestTimeoutException(message: 'Timed out'),
                  AuthenticationException(message: 'Wrong password'),
                  UnauthorizedException(message: 'Token expired'),
                  DatabaseException(message: 'Constraint violated'),
                  ValidationException(message: 'Email is invalid'),
                  LocalStorageException(message: 'Keychain unavailable'),
                  CacheException(message: 'Cache miss'),
                ])
                  ActionChip(
                    label: Text('${exception.runtimeType}'),
                    onPressed: () {
                      try {
                        throw exception;
                      } on AppException catch (e) {
                        context.showError(e.toString());
                      }
                    },
                  ),
              ],
            ),
            Gap.hXs,
            Text(
              'Tap one to throw and catch it — the snackbar shows its '
              'toString().',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A [BaseEntity] subclass, to show what the base class asks of one.
class Hobby extends BaseEntity {
  const Hobby({required super.id, required this.name});

  factory Hobby.fromJson(Map<String, dynamic> json) =>
      Hobby(id: json['id'] as String, name: json['name'] as String);

  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  Hobby copyWith({String? id, String? name}) =>
      Hobby(id: id ?? this.id, name: name ?? this.name);
}

/// A [CrudContract] over a plain map.
///
/// The contract exists so a screen can be written against it and later run on
/// core_architecture_supabase or core_architecture_dio unchanged; this fake is
/// what that looks like with neither installed.
class InMemoryCrud implements CrudContract {
  final Map<String, Map<String, dynamic>> _rows = {
    '1': {'id': '1', 'name': 'Climbing'},
    '2': {'id': '2', 'name': 'Pottery'},
  };

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
    Iterable<Map<String, dynamic>> rows = _rows.values;

    if (filter != null) {
      rows = rows.where(
        (row) => filter.entries.every((e) => row[e.key] == e.value),
      );
    }

    final List<Map<String, dynamic>> sorted = rows.toList();
    if (orderBy != null) {
      sorted.sort((a, b) {
        final int order = '${a[orderBy]}'.compareTo('${b[orderBy]}');
        return ascending ? order : -order;
      });
    }

    final List<Map<String, dynamic>> page = sorted
        .skip(offset ?? 0)
        .take(limit ?? sorted.length)
        .toList();

    return page.map(fromJson).toList();
  }

  @override
  Future<T> getById<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    final Map<String, dynamic>? row = _rows[id];
    if (row == null) {
      throw DatabaseException(message: 'No row with $idColumn $id');
    }
    return fromJson(row);
  }

  @override
  Future<T> insert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    _rows[data['id'] as String] = data;
    return fromJson(data);
  }

  @override
  Future<T> update<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    final Map<String, dynamic>? row = _rows[id];
    if (row == null) {
      throw DatabaseException(message: 'No row with $idColumn $id');
    }
    final Map<String, dynamic> updated = {...row, ...data};
    _rows[id] = updated;
    return fromJson(updated);
  }

  @override
  Future<void> delete({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    _rows.remove(id);
  }

  @override
  Future<List<T>> batchInsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    for (final row in data) {
      _rows[row['id'] as String] = row;
    }
    return data.map(fromJson).toList();
  }

  @override
  Future<List<T>> batchUpdate<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String idColumn = 'id',
  }) async {
    final List<Map<String, dynamic>> updated = [];
    for (final row in data) {
      final String id = row[idColumn] as String;
      final Map<String, dynamic> merged = {...?_rows[id], ...row};
      _rows[id] = merged;
      updated.add(merged);
    }
    return updated.map(fromJson).toList();
  }

  @override
  Future<void> batchDelete({
    required String table,
    required List<String> ids,
    String idColumn = 'id',
  }) async {
    _rows.removeWhere((key, _) => ids.contains(key));
  }

  @override
  Future<bool> exists({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async => _rows.containsKey(id);

  @override
  Future<T> upsert<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  }) async {
    final String id = data['id'] as String;
    final Map<String, dynamic> merged = {...?_rows[id], ...data};
    _rows[id] = merged;
    return fromJson(merged);
  }

  @override
  Future<List<T>> batchUpsert<T>({
    required String table,
    required List<Map<String, dynamic>> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? onConflict,
  }) async {
    final List<Map<String, dynamic>> merged = [];
    for (final row in data) {
      final String id = row['id'] as String;
      final Map<String, dynamic> next = {...?_rows[id], ...row};
      _rows[id] = next;
      merged.add(next);
    }
    return merged.map(fromJson).toList();
  }

  @override
  Future<int> count({
    required String table,
    Map<String, dynamic>? filter,
  }) async {
    if (filter == null) return _rows.length;
    return _rows.values
        .where((row) => filter.entries.every((e) => row[e.key] == e.value))
        .length;
  }

  @override
  Future<dynamic> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    if (functionName != 'longest_name') {
      throw ServerException(message: 'Unknown function $functionName');
    }
    if (_rows.isEmpty) return null;
    return _rows.values
        .map((row) => row['name'] as String)
        .reduce((a, b) => a.length >= b.length ? a : b);
  }
}
