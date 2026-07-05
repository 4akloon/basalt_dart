part of '../table.dart';

/// `LIKE` only makes sense for text columns.
extension TextColumn<Tbl> on TableColumn<String, Tbl> {
  Expression<bool, Tbl> like(String pattern) =>
      Expression(BinaryNode(node, 'LIKE', ParamNode(pattern)));
}
