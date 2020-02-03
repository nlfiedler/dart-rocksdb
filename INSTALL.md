# Install

Start with installing the prerequisites for building RocksDB itself, as described in their [INSTALL.md](https://github.com/facebook/rocksdb/blob/master/INSTALL.md) guide. The instructions below are detailed examples that have been used successfully on various systems. Once the RocksDB prerequisites and the [Dart SDK](https://dart.dev/get-dart) are installed, you can return to the [README.md](./README.md) to build RocksDB and the Dart wrapper.

## Linux

### CentOS 8

These commands are suitable for setting up a clean CentOS 8 system. Feel free to adjust these as necessary. In short, install the RocksDB dependencies, compiler tools, and the Dart SDK.

```shell
$ sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
$ sudo dnf config-manager --set-enabled PowerTools
$ sudo dnf group install 'Development Tools'
# # work around CentOS package bug
$ sudo bash -c 'echo 8 > /etc/yum/vars/releasever'
$ sudo yum install snappy snappy-devel
$ sudo yum install zlib zlib-devel
$ sudo yum install bzip2 bzip2-devel
$ sudo yum install lz4-devel
$ sudo dnf install wget
$ wget https://github.com/facebook/zstd/releases/download/v1.4.4/zstd-1.4.4.tar.gz
$ tar zxf zstd-1.4.4.tar.gz
$ cd zstd-1.4.4/
$ make
$ sudo make install
# # update library path to find libzstd
$ sudo bash -c 'echo /usr/local/lib > /etc/ld.so.conf.d/usr-local.conf'
$ sudo ldconfig
$ cd ..
# # no dart packages for centos at this time...
$ wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.7.1/sdk/dartsdk-linux-x64-release.zip
$ unzip -q dartsdk-linux-x64-release.zip
$ export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:$HOME/dart-sdk/bin
$ hash -r
# # for building the wrapper
$ export DART_SDK=$HOME/dart-sdk
```

### Ubuntu 18

Ubuntu is among the easiest systems to prepare.

```shell
$ sudo apt-get update
$ sudo apt-get install build-essential
$ sudo apt-get install libsnappy-dev
$ sudo apt-get install zlib1g-dev
$ sudo apt-get install libbz2-dev
$ sudo apt-get install liblz4-dev
$ sudo apt-get install libzstd-dev
$ sudo apt-get update
$ sudo apt-get install apt-transport-https
$ sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
$ sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
$ sudo apt-get update
$ sudo apt-get install dart
# # for building the wrapper
$ export DART_SDK=/usr/lib/dart
```

## macOS

You will need the compiler tools at a minimum:

```shell
$ xcode-select --install
```

[Homebrew](https://brew.sh) is the recommended method for installing the Dart SDK on macOS.

```shell
$ brew tap dart-lang/dart
$ brew install dart
```

That seems to be all that is necessary for building RocksDB on macOS. Installing the Homebrew package for RocksDB would defeat the purpose of building it from the included submodule.

## Windows

**TBD**
