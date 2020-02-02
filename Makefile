#
# See README.md for details on building the C++ component.
#

ROCKSDB_SOURCE = rocksdb
# DART_SDK ?= /usr/lib/dart
DART_SDK ?= /usr/local/Cellar/dart/2.7.1/libexec
LIBS = $(ROCKSDB_SOURCE)/librocksdb.a
CFLAGS = -O2 -Wall -std=c++11
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	LIB_NAME = librocksdb.dylib
	LDFLAGS = -dynamic -undefined dynamic_lookup
else ifeq ($(UNAME_S),Linux)
	LIB_NAME = librocksdb.so
	LDFLAGS = -shared -Wl,-lstdc++,-soname,$(LIB_NAME)
	LIBS += -lzstd -lbz2 -lsnappy
endif

all: lib/librocksdb.so

lib/rocksdb.o: lib/rocksdb.cc
	g++ $(CFLAGS) -fPIC -I$(DART_SDK)/include -I$(ROCKSDB_SOURCE)/include -DDART_SHARED_LIB -c lib/rocksdb.cc -o lib/rocksdb.o

lib/librocksdb.so: lib/rocksdb.o
	gcc $(CFLAGS) lib/rocksdb.o $(LDFLAGS) -o lib/$(LIB_NAME) $(LIBS)

clean:
	rm -f lib/*.o lib/$(LIB_NAME)
