import 'package:basalt_codegen/src/queryable/aggregate_info.dart';
import 'package:basalt_codegen/src/queryable/aggregate_join.dart';
import 'package:basalt_codegen/src/queryable/aggregate_query_emitter.dart';
import 'package:basalt_codegen/src/queryable/column_arg.dart';
import 'package:basalt_codegen/src/queryable/class_info.dart';
import 'package:basalt_codegen/src/queryable/has_many_edge.dart';
import 'package:basalt_codegen/src/queryable/has_many_loader_emitter.dart';
import 'package:test/test.dart';

void main() {
  test('AggregateQueryEmitter emits grouped query with joins and orderBy', () {
    final code = const AggregateQueryEmitter().emit(
      className: 'CategoryRevenueRow',
      queryName: 'categoryRevenueRowQuery',
      info: AggregateInfo(
        fromMarker: 'OrderItems',
        joins: [
          AggregateJoin(
            targetMarker: 'Products',
            fkColumnExpr: 'OrderItems.productId',
            nullable: false,
          ),
          AggregateJoin(
            targetMarker: 'Categories',
            fkColumnExpr: 'Products.categoryId',
            nullable: false,
          ),
        ],
        dimensions: [
          ColumnArg(
            paramName: 'categoryName',
            isNamed: false,
            columnExpr: 'Categories.name',
          ),
        ],
        aggregates: [
          AggregateField(
            fieldName: 'revenue',
            selectCall: 'CategoryRevenueRow._revenue()',
            zeroFallback: true,
          ),
        ],
        orderByCall: 'CategoryRevenueRow._revenue()',
        orderDesc: true,
      ),
    );
    expect(code, contains('from(OrderItems.table)'));
    expect(code, contains('.innerJoin(Products.table, onFk: OrderItems.productId)'));
    expect(code, contains('CategoryRevenueRow._revenue()'));
    expect(code, contains('.orderBy(CategoryRevenueRow._revenue().desc())'));
  });

  test('HasManyLoaderEmitter batches children and rebuilds parent rows', () {
    const root = ClassInfo(
      className: 'CustomerProfileRow',
      tableMarker: 'Customers',
      columnArgs: [
        ColumnArg(paramName: 'id', isNamed: false, columnExpr: 'Customers.id'),
        ColumnArg(paramName: 'name', isNamed: false, columnExpr: 'Customers.name'),
      ],
      hasManyEdges: [
        HasManyEdge(
          fieldName: 'addresses',
          childClass: 'AddressRow',
          childMarker: 'Addresses',
          childFkColumnExpr: 'Addresses.customerId',
          childFkParamName: 'customerId',
          parentPkColumnExpr: 'Customers.id',
          parentPkParamName: 'id',
        ),
      ],
      pkColumnExpr: 'Customers.id',
      pkType: 'int',
      pkParamName: 'id',
    );
    const child = ClassInfo(
      className: 'AddressRow',
      tableMarker: 'Addresses',
      columnArgs: [
        ColumnArg(paramName: 'id', isNamed: false, columnExpr: 'Addresses.id'),
        ColumnArg(
          paramName: 'customerId',
          isNamed: false,
          columnExpr: 'Addresses.customerId',
        ),
      ],
    );
    final code = const HasManyLoaderEmitter().emit(
      info: root,
      classInfos: {'CustomerProfileRow': root, 'AddressRow': child},
    );
    expect(code, contains('Future<List<CustomerProfileRow>> loadCustomerProfileRow'));
    expect(code, contains('addressRowQuery.where(Addresses.customerId.isIn(keys))'));
    expect(code, contains('findCustomerProfileRowById'));
  });
}
