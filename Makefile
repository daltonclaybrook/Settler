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
CURRENT_VERSION=0.1.1

.PHONY: build clean test linuxmain xcode install uninstall portable_zip

default: build

build:
	swift build $(SWIFT_BUILD_FLAGS)

clean:
	swift package clean

test:
	swift test

linuxmain:
	swift test --generate-linuxmain

xcode:
	swift package generate-xcodeproj

install: build
	install -d "$(BINARIES_FOLDER)"
	install "$(SETTLER_CLI_EXECUTABLE)" "$(BINARIES_FOLDER)"

uninstall:
	rm -f "$(BINARIES_FOLDER)/settler"

portable_zip: build
	rm -rf "build"
	mkdir -p "build/bin"
	mkdir -p "build/Sources"
	cp -r Sources/Settler build/Sources/
	cp LICENSE README.md build/
	install "$(SETTLER_CLI_EXECUTABLE)" "build/bin"
	(cd build; zip -r -X "Settler-$(CURRENT_VERSION).zip" .)
