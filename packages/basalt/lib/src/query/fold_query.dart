part of 'query.dart';

/// Folds a flat JOIN result set into parent rows (e.g. `@HasMany` codegen).
typedef RowFolder<R> = List<R> Function(List<RowReader> readers);

/// A JOIN [Query] whose SQL rows are folded into fewer parents via [folder].
///
/// Implements [SelectQuery] as `SelectQuery<RowReader>` so `Connection.fetch`
/// returns one [RowReader] per SQL row; call `load` (the
/// `FoldMappedQueryExecute` extension) to run the folder.
///
/// The generative constructor is public (and the class `base`, not `final`)
/// so generated query classes can `extends FoldMappedQuery` and *be* the
/// query.
///
/// {@category queries}
base class FoldMappedQuery<R>
    extends _MappedQueryBase<FoldMappedQuery<R>, RowReader> {
  /// Wraps a built JOIN [query] with a row [folder]. Application code normally
  /// reaches this through [QueryMapFold.mapFold]; subclassing is the codegen
  /// seam.
  ///
  /// The field is named `folder` (not `fold`) so generated subclasses can
  /// expose their `static fold` member without a static/instance name clash.
  FoldMappedQuery(
    super.query,
    this.folder, {
    this.rootPkColumn,
    this.parentLimit,
    this.parentOffset,
  });

  final RowFolder<R> folder;

  /// Root primary key — drives parent-limit subquery serialization.
  final TableColumn<Object?, Object?>? rootPkColumn;
  final int? parentLimit;
  final int? parentOffset;

  @override
  FoldMappedQuery<R> _withQuery(Query<dynamic> query) => FoldMappedQuery(
        query,
        folder,
        rootPkColumn: rootPkColumn,
        parentLimit: parentLimit,
        parentOffset: parentOffset,
      );

  FoldMappedQuery<R> _copyWith({
    int? parentLimit,
    int? parentOffset,
    TableColumn<Object?, Object?>? rootPkColumn,
  }) =>
      FoldMappedQuery(
        _query,
        folder,
        rootPkColumn: rootPkColumn ?? this.rootPkColumn,
        parentLimit: parentLimit ?? this.parentLimit,
        parentOffset: parentOffset ?? this.parentOffset,
      );

  @override
  int? get limitCount => null;
  @override
  int? get offsetCount => null;

  @override
  RowReader Function(List<Object?>) get rowDecoder => _reader;

  /// Limits **parent** rows (subquery on [rootPkColumn]), not flat SQL rows.
  @override
  FoldMappedQuery<R> limit(int count) => _copyWith(parentLimit: count);

  @override
  FoldMappedQuery<R> offset(int count) => _copyWith(parentOffset: count);

  FoldMappedQuery<R> withRootPk(TableColumn<Object?, Object?> pk) =>
      _copyWith(rootPkColumn: pk);
}

/// Attach a row folder after JOINs — use the `FoldMappedQueryExecute.load`
/// extension to run.
extension QueryMapFold on Query<Object?> {
  FoldMappedQuery<R> mapFold<R>(RowFolder<R> fold) =>
      FoldMappedQuery(this, fold);
}
