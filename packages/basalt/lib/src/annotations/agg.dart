import '../schema/table.dart';

/// Binds an aggregate field to a private static [select] tear-off that returns
/// the SQL projection (e.g. `@Agg(CategoryRevenueRow._revenue)`).
///
/// A non-nullable numeric field coalesces SQL NULL (an empty group) to `0` in
/// the generated decoder; declare the field nullable to distinguish "no rows"
/// from an actual zero.
///
/// {@category annotations}
class Agg {
  const Agg(this.select);
  final Selection<Object?> Function() select;
}
