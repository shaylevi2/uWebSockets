EXAMPLE_FILES := HelloWorld ServerName EchoServer BroadcastingEchoServer UpgradeSync UpgradeAsync
THREADED_EXAMPLE_FILES := HelloWorldThreaded EchoServerThreaded
override CXXFLAGS += -lpthread -Wconversion -std=c++17 -Isrc -IuSockets/src
override LDFLAGS += uSockets/*.o -lz

DESTDIR ?=
prefix ?= /usr/local

# WITH_PROXY enables PROXY Protocol v2 support
ifeq ($(WITH_PROXY),1)
	override CXXFLAGS += -DUWS_WITH_PROXY
endif

# WITH_OPENSSL=1 enables OpenSSL 1.1+ support
ifeq ($(WITH_OPENSSL),1)
	# With problems on macOS, make sure to pass needed LDFLAGS required to find these
	override LDFLAGS += -lssl -lcrypto
else
	# WITH_WOLFSSL=1 enables WolfSSL 4.2.0 support (mutually exclusive with OpenSSL)
	ifeq ($(WITH_WOLFSSL),1)
		override LDFLAGS += -L/usr/local/lib -lwolfssl
	endif
endif

# WITH_LIBUV=1 builds with libuv as event-loop
ifeq ($(WITH_LIBUV),1)
	override LDFLAGS += -luv
endif

# WITH_ASAN builds with sanitizers
ifeq ($(WITH_ASAN),1)
	override CXXFLAGS += -fsanitize=address -g
	override LDFLAGS += -lasan
endif

.PHONY: examples
examples:
	$(MAKE) -C uSockets; \
	for FILE in $(EXAMPLE_FILES); do $(CXX) -flto -O3 $(CXXFLAGS) examples/$$FILE.cpp -o $$FILE $(LDFLAGS) & done; \
	for FILE in $(THREADED_EXAMPLE_FILES); do $(CXX) -pthread -flto -O3 $(CXXFLAGS) examples/$$FILE.cpp -o $$FILE $(LDFLAGS) & done; \
	wait

install:
	mkdir -p "$(DESTDIR)$(prefix)/include/uWebSockets/f2"
	cp -r src/* "$(DESTDIR)$(prefix)/include/uWebSockets"

all:
	$(MAKE) examples
	$(MAKE) -C fuzzing
	$(MAKE) -C benchmarks
clean:
	rm -rf $(EXAMPLE_FILES) $(THREADED_EXAMPLE_FILES)
	rm -rf fuzzing/*.o benchmarks/*.o
