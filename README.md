# dart-rocksdb

## Overview

This [Dart](https://dart.dev) package is a wrapper for the [RocksDB](https://rocksdb.org) library. RocksDB is an embeddable persistent key-value store for fast storage. This package aims to expose the RocksDB API in a Dart-friendly fashion.

## Platform Support

### Tested

- Linux
- macOS

### Not Yet Tested

- Android
- iOS
- Windows

### Unsupported

- JavaScript: Due to the native components there is little chance this package will work in JavaScript.

## Basic Usage

Start by building the package's native components and running the tests: see [Build and Test](#build-and-test) below. Eventually this package will mature to the point of being published on [pub.dev](https://pub.dev), but for now it is necessary to build everything locally.

See the `example/main.dart` for an example of how to read, write, and iterate over keys and values. The `example/isolate.dart` code demonstrates accessing a single RocksDB instance from multiple isolates. The `example/json.dart` file shows how to configure custom encoders for keys and values.

## Build and Test

Before beginning, use the instructions in [INSTALL.md](./INSTALL.md) as a guide for setting up your system to build the package and its dependencies. When building RocksDB itself, use the `PORTABLE=1` environment setting to build a portable version of the library.

### Linux

```shell
$ git submodule update --init
$ cd rocksdb && EXTRA_CXXFLAGS='-fPIC' PORTABLE=1 make static_lib
$ make clean all
$ pub get
$ pub run test
```

### macOS

```shell
$ git submodule update --init
$ cd rocksdb && PORTABLE=1 make static_lib
$ make clean all
$ pub get
$ pub run test
```

On recent releases of macOS, it may be necessary to remove the code signature from the `dart` binary, otherwise the OS will prohibit linking with unsigned libraries, like the one built by this package. See [issue #38314](https://github.com/dart-lang/sdk/issues/38314) for additional information and the current status.

```shell
$ codesign --remove-signature $(which dart)
```

## Feature Support

- [x] Read and write keys
- [x] Forward iteration
- [x] Multi-isolate
- [ ] Backward iteration
- [ ] Column Families
- [ ] Snapshots
- [ ] Bulk get / put

## Custom Encoding and Decoding

Using the `RocksDB.openUtf8()` function your application can open a database whose keys and values are `Strings`. However, you can instead specify `keyEncoding` and `valueEncoding` when calling `RocksDB.open()` to open a database with keys and values whose encodings are defined by your application. See [example/json.dart](./example/json.dart) for an example which stores Dart objects in the database using JSON.

## Contributing

Feedback and pull requests are welcome.

## History

This package was originally [created](https://github.com/adamlofts/leveldb_dart) in 2016 by Adam Lofts as a wrapper for [LevelDB](https://github.com/google/leveldb/).

In early 2019 Logan Gorence [converted](https://github.com/SpinlockLabs/rocksdb-dart) the code to link with RocksDB.

Nathan rebuilt the repository history by merging both Adam's and Logan's repositories, then filtering out the frequently updated, and potentially very large, build artifacts in the `lib` directory.

## Resources

### Compiling and Linking

For someone who is not all that familiar with C programming, these resources are very helpful for understanding the process of compiling and linking C/C++ libraries.

* http://www.yolinux.com/TUTORIALS/LibraryArchives-StaticAndDynamic.html
* https://www.cprogramming.com/tutorial/shared-libraries-linux-gcc.html
* https://eli.thegreenplace.net/2013/07/09/library-order-in-static-linking
