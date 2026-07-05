import 'package:basalt_codegen/src/queryable/aggregate_info.dart';
import 'package:basalt_codegen/src/queryable/aggregate_join.dart';
import 'package:basalt_codegen/src/queryable/aggregate_query_emitter.dart';
import 'package:basalt_codegen/src/queryable/class_info.dart';
import 'package:basalt_codegen/src/queryable/column_arg.dart';
import 'package:basalt_codegen/src/queryable/has_many_edge.dart';
import 'package:basalt_codegen/src/queryable/has_many_fold_emitter.dart';
import 'package:basalt_codegen/src/queryable/has_many_query_emitter.dart';
import 'package:test/test.dart';

void main() {
  test('AggregateQueryEmitter emits grouped query with joins and orderBy', () {
    final code = const AggregateQueryEmitter().emit(
      className: 'CategoryRevenueRow',
      queryName: 'categoryRevenueRowQuery',
      info: const AggregateInfo(
        fromMarker: 'OrderItems',
        joins: [
          AggregateJoin(
            parentMarker: 'OrderItems',
            targetMarker: 'Products',
            fkColumnExpr: 'OrderItems.productId',
            nullable: false,
          ),
          AggregateJoin(
            parentMarker: 'Products',
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

  test('AggregateQueryEmitter joins child tables when FROM is the FK target', () {
    final code = const AggregateQueryEmitter().emit(
      className: 'TopCustomerRow',
      queryName: 'topCustomerRowQuery',
      info: const AggregateInfo(
        fromMarker: 'Customers',
        joins: [
          AggregateJoin(
            parentMarker: 'Orders',
            targetMarker: 'Customers',
            fkColumnExpr: 'Orders.customerId',
            nullable: false,
          ),
          AggregateJoin(
            parentMarker: 'OrderItems',
            targetMarker: 'Orders',
            fkColumnExpr: 'OrderItems.orderId',
            nullable: false,
          ),
        ],
        dimensions: [
          ColumnArg(paramName: 'id', isNamed: false, columnExpr: 'Customers.id'),
        ],
        aggregates: [
          AggregateField(
            fieldName: 'totalSpent',
            selectCall: 'TopCustomerRow._totalSpent()',
            zeroFallback: true,
          ),
        ],
      ),
    );
    expect(code, contains('from(Customers.table)'));
    expect(code, contains('.innerJoin(Orders.table, onFk: Orders.customerId)'));
    expect(
      code,
      contains('.innerJoin(OrderItems.table, onFk: OrderItems.orderId)'),
    );
    expect(code, isNot(contains('Customers.table, onFk: Orders.customerId')));
  });

  test('HasManyQueryEmitter emits fold query with LEFT JOINs', () {
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
      pkColumnExpr: 'Addresses.id',
      pkType: 'int',
      pkParamName: 'id',
    );
    final queryCode = const HasManyQueryEmitter().emit(
      root: root,
      classInfos: {'CustomerProfileRow': root, 'AddressRow': child},
      queryName: 'customerProfileRowQuery',
      foldName: r'$CustomerProfileRowFold',
    );
    expect(queryCode, contains('FoldMappedQuery<CustomerProfileRow>'));
    expect(queryCode, contains('.leftJoin('));
    expect(queryCode, isNot(contains('.innerJoin(addressesCustomer')));
    expect(queryCode, contains(r'.mapFold($CustomerProfileRowFold)'));
    expect(queryCode, contains('.withRootPk(Customers.id)'));

    final foldCode = const HasManyFoldEmitter().emit(
      root: root,
      classInfos: {'CustomerProfileRow': root, 'AddressRow': child},
    );
    expect(foldCode, contains(r'List<CustomerProfileRow> $CustomerProfileRowFold'));
    expect(foldCode, isNot(contains('loadCustomerProfileRow')));
  });
}
