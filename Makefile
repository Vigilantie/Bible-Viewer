BUILD_DIR   := build
DEBUG_DIR   := build/debug
RELEASE_DIR := build/release

UNAME_S := $(shell uname -s)

ifeq ($(OS),Windows_NT)
  PLATFORM := windows
else ifeq ($(UNAME_S),Darwin)
  PLATFORM := macos
else ifeq ($(UNAME_S),Linux)
  PLATFORM := linux
else
  PLATFORM := unknown
endif

ifeq ($(PLATFORM),macos)
  CMAKE_GENERATOR := -G Xcode
else
  CMAKE_GENERATOR :=
endif

.PHONY: all library debug debug-lib release release-lib

all: release

library: release-lib

debug:
ifeq ($(PLATFORM),macos)
	cmake -S . -B $(DEBUG_DIR) -G Xcode
	cmake --build $(DEBUG_DIR) --config Debug
else
	cmake -S . -B $(DEBUG_DIR) -DCMAKE_BUILD_TYPE=Debug
	cmake --build $(DEBUG_DIR)
endif

debug-lib:
ifeq ($(PLATFORM),macos)
	cmake -S . -B $(DEBUG_DIR) -G Xcode -DGUI=OFF
	cmake --build $(DEBUG_DIR) --config Debug
else
	cmake -S . -B $(DEBUG_DIR) -DCMAKE_BUILD_TYPE=Debug -DGUI=OFF
	cmake --build $(DEBUG_DIR)
endif

release:
ifeq ($(PLATFORM),macos)
	cmake -S . -B $(RELEASE_DIR) -G Xcode
	cmake --build $(RELEASE_DIR) --config Release
else
	cmake -S . -B $(RELEASE_DIR) -DCMAKE_BUILD_TYPE=Release
	cmake --build $(RELEASE_DIR)
endif

release-lib:
ifeq ($(PLATFORM),macos)
	cmake -S . -B $(RELEASE_DIR) -G Xcode -DGUI=OFF
	cmake --build $(RELEASE_DIR) --config Release
else
	cmake -S . -B $(RELEASE_DIR) -DCMAKE_BUILD_TYPE=Release -DGUI=OFF
	cmake --build $(RELEASE_DIR)
endif

clean:
	rm -rf $(BUILD_DIR)
