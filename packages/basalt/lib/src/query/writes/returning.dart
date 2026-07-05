part of '../write.dart';

/// Intermediate builder from [WriteReturning.returning]; call [map] / [mapWith]
/// to attach a row decoder and produce an executable [ReturningQuery].
final class Returning {
  final WriteStatement _statement;
  final List<TableColumn<Object?, Object?>> _columns;
  const Returning(this._statement, this._columns);

  ReturningQuery<R> map<R>(R Function(RowReader reader) decode) =>
      ReturningQuery._(
        _statement,
        [
          for (final c in _columns)
            Projection(c.selectExpression, alias: c.selectAlias),
        ],
        {for (var i = 0; i < _columns.length; i++) _columns[i].readKey: i},
        decode,
      );

  ReturningQuery<R> mapWith<R>(RowMapper<R> mapper) => map(mapper.read);
}
