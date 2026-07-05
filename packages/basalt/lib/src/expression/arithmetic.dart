import '../ast/sql_node.dart';
import '../schema/table.dart';
import 'expression.dart';

/// ponytail: [Object] operand — column, expression, or num literal only.
SqlNode _arithOperand(Object operand) {
  if (operand is TableColumn<num, dynamic>) return operand.node;
  if (operand is Expression<num, dynamic>) return operand.node;
  if (operand is num) return ParamNode(operand);
  throw ArgumentError('Arithmetic operand must be a column, expression, or num');
}

Expression<num, Tbl> _arith<Tbl>(SqlNode left, String op, Object right) =>
    Expression(BinaryNode(left, op, _arithOperand(right)));

/// Typed arithmetic on numeric columns and expressions.
extension NumColumnArithmetic<Tbl> on TableColumn<num, Tbl> {
  Expression<num, Tbl> operator +(Object other) => _arith(node, '+', other);
  Expression<num, Tbl> operator -(Object other) => _arith(node, '-', other);
  Expression<num, Tbl> operator *(Object other) => _arith(node, '*', other);
  Expression<num, Tbl> operator /(Object other) => _arith(node, '/', other);
}

extension NumExpressionArithmetic<Tbl> on Expression<num, Tbl> {
  Expression<num, Tbl> operator +(Object other) =>
      _arith(node, '+', other);
  Expression<num, Tbl> operator -(Object other) =>
      _arith(node, '-', other);
  Expression<num, Tbl> operator *(Object other) =>
      _arith(node, '*', other);
  Expression<num, Tbl> operator /(Object other) =>
      _arith(node, '/', other);
}
