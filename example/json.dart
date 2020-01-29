import 'dart:async';

import 'package:rocksdb/rocksdb.dart';
import 'dart:convert';

/// Example of using a JSON codec
/// Output is:
/// Key: hello
/// Key: world
/// Value: [{some: value}, 2]
/// Value: {a: 5, b: 10, c: Hey}
Future<dynamic> main() async {
  // Create a codec which encodes
  //   dart object -> JSON -> utf8 -> Uint8List
  var valueCodec =
      const JsonCodec().fuse(const Utf8Codec()).fuse(const Uint8ListCodec());

  // Create a DB using this codec
  var db = await RocksDB.open<String, Object>('/tmp/testdb/json',
      keyEncoding: RocksDB.utf8, valueEncoding: valueCodec);

  // The objects we store must follow the JSON rules (only string keys in maps) etc...
  Object object1 = <Object>[
    <String, String>{'some': 'value'},
    2
  ];
  Object object2 = <Object, Object>{'a': 5, 'b': 10, 'c': 'Hey'};

  // Add an objects to the db
  db.put('hello', object1);
  db.put('world', object2);

  // Print the values in the database. Iteration is in key order.
  for (var key in db.getItems().keys) {
    print('Key: $key');
  }
  for (var value in db.getItems().values) {
    print('Value: $value');
  }
  db.close();
}
