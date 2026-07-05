import 'package:basalt_codegen/src/queryable/changeset_emitter.dart';
import 'package:basalt_codegen/src/queryable/column_arg.dart';
import 'package:basalt_codegen/src/queryable/insert_emitter.dart';
import 'package:basalt_codegen/src/queryable/reader_emitter.dart';
import 'package:test/test.dart';

void main() {
  const insertEmitter = InsertEmitter();
  const changesetEmitter = ChangesetEmitter();
  const readerEmitter = ReaderEmitter();

  // id: readOnly (autoincrement-style), token: writeOnly (insert but never read).
  const columns = [
    ColumnArg(
        paramName: 'id',
        isNamed: false,
        columnExpr: 'Users.id',
        readOnly: true),
    ColumnArg(paramName: 'name', isNamed: false, columnExpr: 'Users.name'),
    ColumnArg(paramName: 'age', isNamed: false, columnExpr: 'Users.age'),
    ColumnArg(
        paramName: 'token',
        isNamed: true,
        columnExpr: 'Users.token',
        writeOnly: true),
  ];

  group('InsertEmitter', () {
    final code = insertEmitter.emit(
      className: 'User',
      tableMarker: 'Users',
      columnArgs: columns,
    );

    test('emits a toInsert() extension returning an InsertStatement', () {
      expect(code, contains('extension UserInsert on User {'));
      expect(
          code,
          contains(
              'InsertStatement<Users> toInsert() => insertInto(Users.table)'));
    });

    test('sets every writable column (incl. writeOnly) via TableColumn.set', () {
      expect(code, contains('.value(Users.name.set(name))'));
      expect(code, contains('.value(Users.age.set(age))'));
      expect(code, contains('.value(Users.token.set(token))'));
    });

    test('omits readOnly columns from the INSERT', () {
      expect(code, isNot(contains('Users.id.set')));
    });
  });

  group('ChangesetEmitter', () {
    final code = changesetEmitter.emit(
      className: 'User',
      tableMarker: 'Users',
      columnArgs: columns,
    );

    test('emits a toUpdate() extension returning an UpdateStatement', () {
      expect(code, contains('extension UserChangeset on User {'));
      expect(code,
          contains('UpdateStatement<Users> toUpdate() => update(Users.table)'));
    });

    test('SETs writable columns and omits readOnly (PK stays in WHERE)', () {
      expect(code, contains('.value(Users.name.set(name))'));
      expect(code, contains('.value(Users.token.set(token))'));
      expect(code, isNot(contains('Users.id.set')));
    });
  });

  group('ReaderEmitter direction', () {
    test('reads readOnly columns but omits writeOnly ones', () {
      final code = readerEmitter.emit(
        className: 'User',
        readerName: r'$UserFromRow',
        tableMarker: 'Users',
        columnArgs: columns,
        relationArgs: const [],
      );
      expect(code, contains('r.get(src.col(Users.id))')); // readOnly -> still read
      expect(code, contains('r.get(src.col(Users.name))'));
      expect(code, isNot(contains('Users.token'))); // writeOnly -> not read
    });
  });
}
