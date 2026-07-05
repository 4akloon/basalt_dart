import '../schema/table.dart';

/// Binds an aggregate field to a private static [select] tear-off that returns
/// the SQL projection (e.g. `@Agg(CategoryRevenueRow._revenue)`).
///
/// {@category annotations}
class Agg {
  const Agg(this.select);
  final Selection<Object?> Function() select;
}
