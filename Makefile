#
# Users of this package should not need to run this Makefile.
#
# First build a static RocksDB library.
#
# On Linux, build RocksDB like so:
#
# $ EXTRA_CFLAGS='-D_GLIBCXX_USE_CXX11_ABI=0 -std=c++11' \
#   EXTRA_CXXFLAGS='-D_GLIBCXX_USE_CXX11_ABI=0 -std=c++11 -fPIC' \
#   make static_lib
#
# The -fPIC enables linking the static library into the object we will build.
# -D_GLIBCXX_USE_CXX11_ABI turns off the new C++11 ABI, which means the build
# will be backward compatible with older Linux versions.
#

ROCKSDB_SOURCE = rocksdb
# Location of Dart SDK (/usr/lib/dart on Linux)
DART_SDK ?= /usr/local/Cellar/dart/2.7.1/libexec
LIBS = $(ROCKSDB_SOURCE)/librocksdb.a
CFLAGS = -O2 -Wall -D_GLIBCXX_USE_CXX11_ABI=0 -std=c++11
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	LIB_NAME = librocksdb.dylib
	LDFLAGS = -dynamic -undefined dynamic_lookup
else ifeq ($(UNAME_S),Linux)
	LIB_NAME = librocksdb.so
	LDFLAGS = -shared -Wl,-lstdc++,-soname,$(LIB_NAME)
endif

all: lib/librocksdb.so

lib/rocksdb.o: lib/rocksdb.cc
	g++ $(CFLAGS) -fPIC -I$(DART_SDK)/include -I$(ROCKSDB_SOURCE)/include -DDART_SHARED_LIB -c lib/rocksdb.cc -o lib/rocksdb.o

lib/librocksdb.so: lib/rocksdb.o
	gcc $(CFLAGS) lib/rocksdb.o $(LDFLAGS) -o lib/$(LIB_NAME) $(LIBS)

clean:
	rm -f lib/*.o lib/*.so lib/*.dylib
