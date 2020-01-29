# dart-rocksdb

## Overview

This [Dart](https://dart.dev) package is a wrapper for the [RocksDB](https://rocksdb.org) library. RocksDB is an embeddable persistent key-value store for fast storage. This package aims to expose the RocksDB API in a Dart-friendly fashion.

## Platform Support

- [ ] Android
- [ ] iOS
- [ ] JavaScript
- [ ] Linux
- [x] macOS
- [ ] Windows

## Basic Usage

Add `rocksdb` to the `dependencies` in the `pubspec.yaml` file and run `pub get`.

Check out `example/main.dart` to see how to read, write, and iterate over keys and values.

## Build and Test

These steps are for working on the dart-rocksdb package itself. Before beginning, be sure to install the prerequisites for building RocksDB itself, as described in the [INSTALL.md](https://github.com/facebook/rocksdb/blob/master/INSTALL.md).

```shell
$ git submodule update --init
$ cd rocksdb
$ make static_lib
$ cd ..
$ make clean && make
$ pub run test
```

### macOS

On recent releases of macOS, it may be necessary to remove the code signature from the `dart` binary, otherwise the OS will prohibit linking with unsigned libraries, like the one built by this package.

```shell
$ codesign --remove-signature /usr/local/bin/dart
```

## Feature Support

- [x] Read and write keys
- [x] Forward iteration
- [x] Multi-isolate
- [ ] Backward iteration
- [ ] Snapshots
- [ ] Bulk get / put

## Custom Encoding and Decoding

Using the `RocksDB.openUtf8()` function your application can open a database whose keys and values are `Strings`. However, you can instead specify `keyEncoding` and `valueEncoding` when calling `RocksDB.open()` to open a database with keys and values whose encodings are defined by your application. See [example/json.dart](./example/json.dart) for an example which stores Dart objects in the database using JSON.

## Contributing

Feedback and pull requests are welcome.

## History and Credit

This package was originally [created](https://github.com/adamlofts/leveldb_dart) in 2016 by Adam Lofts as a wrapper for [LevelDB](https://github.com/google/leveldb/).

In early 2019 Logan Gorence [converted](https://github.com/SpinlockLabs/rocksdb-dart) the code to link with RocksDB.
