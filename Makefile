SWIFT_BUILD_FLAGS=--configuration release
UNAME=$(shell uname)
ifeq ($(UNAME), Darwin)
USE_SWIFT_STATIC_STDLIB:=$(shell test -d $$(dirname $$(xcrun --find swift))/../lib/swift_static/macosx && echo yes)
ifeq ($(USE_SWIFT_STATIC_STDLIB), yes)
SWIFT_BUILD_FLAGS+= -Xswiftc -static-stdlib
endif
endif

BINARIES_FOLDER=/usr/local/bin
SETTLER_CLI_EXECUTABLE=$(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/settler

.PHONY: build clean test linuxmain install uninstall

default: build

build:
	swift build $(SWIFT_BUILD_FLAGS)

clean:
	swift package clean

test:
	swift test

linuxmain:
	swift test --generate-linuxmain

install: build
	install -d "$(BINARIES_FOLDER)"
	install "$(SETTLER_CLI_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	rm -f "$(BINARIES_FOLDER)/settler"
