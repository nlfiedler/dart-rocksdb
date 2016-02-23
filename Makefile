

all: lib/libleveldb.so

LIBS=-lleveldb

lib/leveldb.o: lib/leveldb.cc
	g++ -O2 -fPIC  -I$(DART_SDK) -DDART_SHARED_LIB -c lib/leveldb.cc -o lib/leveldb.o -std=c++11 #-m32

lib/libleveldb.so: lib/leveldb.o
	gcc -O2 -shared -Wl,-soname,libleveldb.so -o lib/libleveldb.so lib/leveldb.o $(LIBS) #-m32 

clean:
	rm -f lib/*.o lib/*.so
