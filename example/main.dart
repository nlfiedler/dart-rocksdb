//
// Copyright (c) 2016 Adam Lofts
// Copyright (c) 2019 Logan Gorence
//
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rocksdb/rocksdb.dart';

Future<dynamic> main() async {
  // Open a database. It is created if it does not already exist. Only one
  // process can open a database at a time.
  var tp = p.join(Directory.systemTemp.path, 'dart-rocksdb', 'main');
  await Directory(tp).create(recursive: true);
  var db = await RocksDB.openUtf8(tp);

  // By default keys and values are strings.
  db.put('abc', 'def');
  var value = db.get('abc');
  print('value is $value');
  db.delete('abc');

  // If a key does not exist we get null back
  var value3 = db.get('abc');
  print('value3 is $value3');

  // Now lets add a few key-value pairs
  for (var i in Iterable<int>.generate(5)) {
    db.put('key-$i', 'value-$i');
  }

  // Iterate through the key-value pairs in key order.
  for (var v in db.getItems()) {
    print('Row: ${v.key} ${v.value}');
  }

  // Iterate keys between key-1 and key-3
  for (var v in db.getItems(gte: 'key-1', lte: 'key-3')) {
    print('Row: ${v.key} ${v.value}');
  }

  // Iterate explicitly. This avoids allocation of RocksItem objects if you
  // never call it.current.
  var it = db.getItems(limit: 1).iterator;
  while (it.moveNext()) {
    print('${it.currentKey} ${it.currentValue}');
  }

  // Just key iteration
  for (dynamic key in db.getItems().keys) {
    print('Key $key');
  }

  // Value iteration
  for (dynamic value in db.getItems().values) {
    print('Value $value');
  }

  // Close the db. This free's all resources associated with the db. All
  // iterators will throw if used after this call.
  db.close();

  // Open a new db which will use raw UInt8List data. This is faster since it
  // avoids any decoding.
  var db2 = await RocksDB.openUint8List(tp);
  for (var item in db2.getItems()) {
    print('${item.key}');
  }
  db2.close();

  var d = Directory(tp);
  await d.delete(recursive: true);
}
