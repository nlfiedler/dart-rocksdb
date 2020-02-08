//
// Copyright (c) 2016 Adam Lofts
// Copyright (c) 2019 Logan Gorence
// Copyright (c) 2020 Nathan Fiedler
//
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:rocksdb/rocksdb.dart';

final dbPaths = <String>{};

// Create a temporary path for the database files.
String generateTempPath(String suffix) {
  var tp = p.join(Directory.systemTemp.path, 'dart-rocksdb', 'test-${suffix}');
  var d = Directory(tp);
  d.createSync(recursive: true);
  return tp;
}

const Matcher _isClosedError = _ClosedMatcher();

class _ClosedMatcher extends TypeMatcher<RocksClosedError> {
  const _ClosedMatcher();
}

const Matcher _isInvalidArgumentError = _InvalidArgumentMatcher();

class _InvalidArgumentMatcher extends TypeMatcher<RocksInvalidArgumentError> {
  const _InvalidArgumentMatcher();
}

void main() {
  tearDown(() async {
    // make a copy of the current elements to allow pruning the set
    var copy = dbPaths.toSet();
    for (var tp in copy) {
      var d = Directory(tp);
      if (d.existsSync()) {
        await d.delete(recursive: true);
      }
    }
    dbPaths.removeAll(copy);
  });

  test('basic operations', () async {
    var path = generateTempPath('basics');
    var db = await RocksDB.openUtf8(path);

    db.put('k1', 'v');
    db.put('k2', 'v');

    expect(db.get('k1'), equals('v'));
    List<dynamic> keys = db.getItems().keys.toList();
    expect(keys.first, equals('k1'));

    var v = db.get('DOESNOTEXIST');
    expect(v, equals(null));

    // All keys
    keys = db.getItems().keys.toList();
    expect(keys.length, equals(2));
    keys = db.getItems(gte: 'k1').keys.toList();
    expect(keys.length, equals(2));
    keys = db.getItems(gt: 'k1').keys.toList();
    expect(keys.length, equals(1));

    keys = db.getItems(gt: 'k0').keys.toList();
    expect(keys.length, equals(2));

    keys = db.getItems(gt: 'k5').keys.toList();
    expect(keys.length, equals(0));
    keys = db.getItems(gte: 'k5').keys.toList();
    expect(keys.length, equals(0));

    keys = db.getItems(limit: 1).keys.toList();
    expect(keys.length, equals(1));

    keys = db.getItems(lte: 'k2').keys.toList();
    expect(keys.length, equals(2));
    keys = db.getItems(lt: 'k2').keys.toList();
    expect(keys.length, equals(1));

    keys = db.getItems(gt: 'k1', lt: 'k2').keys.toList();
    expect(keys.length, equals(0));

    keys = db.getItems(gte: 'k1', lt: 'k2').keys.toList();
    expect(keys.length, equals(1));

    keys = db.getItems(gt: 'k1', lte: 'k2').keys.toList();
    expect(keys.length, equals(1));

    keys = db.getItems(gte: 'k1', lte: 'k2').keys.toList();
    expect(keys.length, equals(2));

    db.close();

    var db2 = await RocksDB.open(path,
        keyEncoding: RocksDB.identity, valueEncoding: RocksDB.identity);

    // Test with RocksEncodingNone
    var key = Uint8List(2);
    key[0] = 'k'.codeUnitAt(0);
    key[1] = '1'.codeUnitAt(0);
    keys = db2.getItems(gt: key).keys.toList();
    expect(keys.length, equals(1));

    keys = db2.getItems(gte: key).keys.toList();
    expect(keys.length, equals(2));

    key[1] = '2'.codeUnitAt(0);
    keys = db2.getItems(gt: key).keys.toList();
    expect(keys.length, equals(0));

    keys = db2.getItems(gte: key).keys.toList();
    expect(keys.length, equals(1));

    keys = db2.getItems(lt: key).keys.toList();
    expect(keys.length, equals(1));

    keys = db2.getItems(lt: key).values.toList();
    expect(keys.length, equals(1));

    db2.close();
    dbPaths.add(path);
  });

  test('delete entry', () async {
    var path = generateTempPath('delete');
    var db = await RocksDB.openUtf8(path);
    try {
      db.put('k1', 'v');
      db.put('k2', 'v');

      db.delete('k1');

      expect(db.get('k1'), equals(null));
      expect(db.getItems().length, 1);
    } finally {
      db.close();
      dbPaths.add(path);
    }
  });

  test('two separate databases', () async {
    var path1 = generateTempPath('two-db-1');
    var db1 = await RocksDB.openUtf8(path1);
    var path2 = generateTempPath('two-db-2');
    var db2 = await RocksDB.openUtf8(path2);

    db1.put('a', '1');

    var v = db2.get('a');
    expect(v, equals(null));

    db1.close();
    dbPaths.add(path1);
    db2.close();
    dbPaths.add(path2);
  });

  test('use after close', () async {
    var path = generateTempPath('close');
    var db = await RocksDB.openUtf8(path);
    db.close();

    expect(() => db.get('SOME KEY'), throwsA(_isClosedError));
    expect(() => db.delete('SOME KEY'), throwsA(_isClosedError));
    expect(() => db.put('SOME KEY', 'SOME KEY'), throwsA(_isClosedError));
    expect(() => db.close(), throwsA(_isClosedError));

    try {
      for (var _ in db.getItems()) {
        expect(true, equals(false)); // Should not happen.
      }
    } on RocksClosedError {
      expect(true, equals(true)); // Should happen.
    }
    dbPaths.add(path);
  });

  test('locking throws an error', () async {
    var path = generateTempPath('locking');
    var db = await RocksDB.openUtf8(path);
    try {
      await RocksDB.openUtf8(path);
      expect(true, equals(false)); // Should not happen. The db is locked.
    } on RocksIOError {
      expect(true, equals(true)); // Should happen.
    } finally {
      db.close();
      dbPaths.add(path);
    }
  });

  test('throw inside iteration', () async {
    var path = generateTempPath('bad-iter');
    var db = await RocksDB.openUtf8(path);
    db.put('a', '1');
    db.put('b', '1');
    db.put('c', '1');

    try {
      for (var _ in db.getItems()) {
        throw Exception('OH NO');
      }
    } catch (e) {
      // Pass
    } finally {
      db.close();
      dbPaths.add(path);
    }
  });

  test('key-value encoding', () async {
    var path = generateTempPath('encoding');
    var dbNone = await RocksDB.open(path,
        keyEncoding: RocksDB.identity,
        valueEncoding: RocksDB.identity,
        shared: true);
    var dbAscii = await RocksDB.open(path,
        keyEncoding: RocksDB.ascii, valueEncoding: RocksDB.ascii, shared: true);
    var dbUtf8 = await RocksDB.open(path,
        keyEncoding: RocksDB.utf8, valueEncoding: RocksDB.utf8, shared: true);
    var v = Uint8List.fromList(utf8.encode('key1'));
    dbNone.put(v, v);

    var s = dbUtf8.get('key1');
    expect(s, equals('key1'));

    var s2 = dbAscii.get('key1');
    expect(s2, equals('key1'));

    var v2 = dbNone.get(v);
    expect(v2, equals(v));

    dbNone.delete(v);
    expect(dbNone.get(v), null);
    dbNone.close();

    expect(dbAscii.get('key1'), null);
    dbAscii.close();

    expect(dbUtf8.get('key1'), null);
    dbUtf8.close();
    dbPaths.add(path);
  });

  test('close inside iteration', () async {
    var path = generateTempPath('close-iter');
    var db = await RocksDB.openUtf8(path);
    db.put('a', '1');
    db.put('b', '1');

    var isClosedSeen = false;

    try {
      for (var _ in db.getItems()) {
        db.close();
      }
    } on RocksClosedError catch (_) {
      isClosedSeen = true;
    }

    expect(isClosedSeen, equals(true));
    dbPaths.add(path);
  });

  test('no create if missing', () async {
    var tp = p.join(Directory.systemTemp.path, 'dart-rocksdb', 'notexist');
    expect(RocksDB.openUtf8(tp, createIfMissing: false),
        throwsA(_isInvalidArgumentError));
    dbPaths.add(tp);
  });

  test('throw error if exists', () async {
    var tp = p.join(Directory.systemTemp.path, 'dart-rocksdb', 'exists');
    var d = Directory(tp);
    await d.create(recursive: true);
    var db = await RocksDB.openUtf8(tp);
    db.close();
    expect(RocksDB.openUtf8(tp, errorIfExists: true),
        throwsA(_isInvalidArgumentError));
    dbPaths.add(tp);
  });

  test('iteration', () async {
    var path = generateTempPath('sync-iter');
    var db = await RocksDB.openUtf8(path);

    db.put('k1', 'v');
    db.put('k2', 'v');

    var items1 = db.getItems().toList();
    expect(items1.length, equals(2));
    expect(items1.map((RocksItem<String, String> i) => i.key).toList(),
        equals(<String>['k1', 'k2']));
    expect(items1.map((RocksItem<String, String> i) => i.value).toList(),
        equals(<String>['v', 'v']));

    var items = db.getItems(gte: 'k1').toList();
    expect(items.length, equals(2));
    items = db.getItems(gt: 'k1').toList();
    expect(items.length, equals(1));

    items = db.getItems(gt: 'k0').toList();
    expect(items.length, equals(2));

    items = db.getItems(gt: 'k5').toList();
    expect(items.length, equals(0));
    items = db.getItems(gte: 'k5').toList();
    expect(items.length, equals(0));

    items = db.getItems(limit: 1).toList();
    expect(items.length, equals(1));

    items = db.getItems(lte: 'k2').toList();
    expect(items.length, equals(2));
    items = db.getItems(lt: 'k2').toList();
    expect(items.length, equals(1));

    items = db.getItems(gt: 'k1', lt: 'k2').toList();
    expect(items.length, equals(0));

    items = db.getItems(gte: 'k1', lt: 'k2').toList();
    expect(items.length, equals(1));

    items = db.getItems(gt: 'k1', lte: 'k2').toList();
    expect(items.length, equals(1));

    items = db.getItems(gte: 'k1', lte: 'k2').toList();
    expect(items.length, equals(2));

    var val =
        'bv-12345678901234567890123456789012345678901234567890123456789012345678901234567890';
    db.put('a', val);
    var item = db.getItems(lte: 'a').first;
    expect(item.value.length, val.length);

    var longKey = '';
    for (var _ in Iterable<int>.generate(10)) {
      longKey += val;
    }
    db.put(longKey, longKey);
    item = db.getItems(gt: 'a', lte: 'c').first;
    expect(item.value.length, longKey.length);

    db.close();
    dbPaths.add(path);
  });

  test('iterator use after close', () async {
    var path = generateTempPath('after-close');
    var db = await RocksDB.openUtf8(path);

    db.put('k1', 'v');
    db.put('k2', 'v');

    Iterator<RocksItem<String, String>> it = db.getItems().iterator;
    it.moveNext();

    db.close();
    dbPaths.add(path);

    expect(() => it.moveNext(), throwsA(_isClosedError));
  });

  test('iterator end current == null', () async {
    var path = generateTempPath('null-iter');
    var db = await RocksDB.openUtf8(path);

    db.put('k1', 'v');
    var it = db.getItems().iterator;
    expect(it.current, null);
    expect(it.currentKey, null);
    expect(it.currentValue, null);

    it.moveNext();
    expect(it.current.key, 'k1');
    expect(it.currentKey, 'k1');
    expect(it.currentValue, 'v');
    expect(it.moveNext(), false);
    expect(it.current, null);
    for (var _ in Iterable<int>.generate(10)) {
      // Dart requires that it is safe to call moveNext after the end.
      expect(it.moveNext(), false);
      expect(it.current, null);
      expect(it.currentKey, null);
      expect(it.currentValue, null);
    }
    db.close();
    dbPaths.add(path);
  });

  test('shared instance in one isolate', () async {
    var path = generateTempPath('shared-isolate');
    var db1 = await RocksDB.openUtf8(path, shared: true);
    var db2 = await RocksDB.openUtf8(path, shared: true);

    db1.put('k1', 'v');
    expect(db2.get('k1'), 'v');

    // close the first reference, it cannot be used now
    db1.close();
    expect(() => db1.get('SOME KEY'), throwsA(_isClosedError));

    // db2 should still work.
    db2.put('k1', 'v2');
    expect(db2.get('k1'), 'v2');

    // close the second reference, it cannot be used now
    db2.close();
    expect(() => db2.get('SOME KEY'), throwsA(_isClosedError));
    dbPaths.add(path);
  });

  test('instance removed from map on close', () async {
    // Test that a shared db is correctly removed from the shared map after it
    // has been closed.
    var path = generateTempPath('series');
    var db1 = await RocksDB.openUtf8(path, shared: true);
    db1.close();

    // Since the db is closed above it will be remove from the shared map and
    // therefore this will open a new db and we are allowed to read/write keys.
    var db2 = await RocksDB.openUtf8(path, shared: true);
    db2.put('k1', 'v');
    expect(db2.get('k1'), 'v');
    db2.close();
    dbPaths.add(path);
  });

  test('shared instance multiple isolates', () async {
    // Spawn multiple isolates which open and close a shared database in an
    // attempt to find race conditions in opening and closing the database.
    var path = generateTempPath('parallel');
    Future<Null> run(int index) {
      var completer = Completer<Null>();
      var exitPort = RawReceivePort((dynamic _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      var errorPort = RawReceivePort((dynamic v) => completer.completeError(v));
      Isolate.spawn(_isolateTest, path,
          onExit: exitPort.sendPort, onError: errorPort.sendPort);
      return completer.future;
    }

    await Future.wait(Iterable<int>.generate(10).map(run), eagerError: true);
    dbPaths.add(path);
  });
}

// Must be a top-level because this function runs in another isolate.
Future<Null> _isolateTest(String path) async {
  for (var _ in Iterable<int>.generate(200)) {
    var db = await RocksDB.openUtf8(path, shared: true);
    // Allocate an iterator.
    for (var _ in db.getItems(limit: 2)) {
      // pass
    }
    db.close();

    await Future<Null>.delayed(Duration(milliseconds: 2));
  }
}
