//
// Copyright (c) 2016 Adam Lofts
// Copyright (c) 2019 Logan Gorence
//
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:rocksdb/rocksdb.dart';

final dbpath = p.join(Directory.systemTemp.path, 'dart-rocksdb', 'isolate');

/// This example demonstrates how to access a database from multiple isolates.
/// Isolates are implemented as os-threads in the dart vm so this allows you to
/// use multiple cores. Access to the underlying rocks db from multiple isolates is safe.
Future<dynamic> main() async {
  // Spawn some isolates. Each of these will write a key then read a key from the next thread.
  var runners = Iterable<int>.generate(5).map((int index) {
    return Runner.spawn(index);
  }).toList();

  await Future.wait(runners.map((Runner r) => r.finish));
  var d = Directory(dbpath);
  if (d.existsSync()) {
    await d.delete(recursive: true);
  }
}

/// This method is called in different OS threads by the dart VM.
Future<Null> run(int index) async {
  // Because shared: true is passed the DB returned by this method will reference the same
  // database.
  await Directory(dbpath).create(recursive: true);
  var db = await RocksDB.openUtf8(dbpath, shared: true);

  // Write our key to the db
  print('Thread $index write key $index -> $index');
  db.put('$index', '$index');

  // Sleep 1 second
  await Future<Null>.delayed(const Duration(seconds: 1));

  // Now read the key from the next thread
  var nextKey = '${(index + 1) % 5}';
  print('Thread $index read key $nextKey -> ${db.get(nextKey)}');
}

/// Helper class to run an isolate and wait for it to finish.
class Runner {
  final Completer<Null> _finish = Completer<Null>();
  final RawReceivePort _finishPort = RawReceivePort();

  /// Run an isolate.
  Runner.spawn(int index) {
    _finishPort.handler = (dynamic _) {
      _finish.complete();
      _finishPort.close();
    };
    Isolate.spawn(run, index, onExit: _finishPort.sendPort);
  }

  /// Future completed when the isolate exits normally.
  Future<Null> get finish => _finish.future;
}
