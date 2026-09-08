# ============================================================
# ARMCall Tests
# Android ARM32 / ARM64
# ============================================================

NAME := armcall

ROOT := ..
BUILD := $(ROOT)/build
OUT := $(BUILD)/lib
OBJ := $(BUILD)/test

SRC := .
INCLUDES := -I$(ROOT)/src

API ?= 21
ARCH ?= arm32

# ============================================================
# Toolchain
# ============================================================

CLANGXX := clang++
LLVM_STRIP := llvm-strip

# ============================================================
# Architecture Configuration
# ============================================================

ifeq ($(ARCH),arm32)

ABI := armeabi-v7a
TARGET := armv7a-linux-androideabi$(API)

CXXFLAGS := \
	-std=c++17 \
	-fPIC \
	-O2 \
	-Wall \
	-Wextra \
	-Wpedantic \
	--target=$(TARGET) \
	-march=armv7-a \
	-mthumb \
	-mfloat-abi=softfp

LDFLAGS := \
	--target=$(TARGET)

ARMCall_LIB := \
	$(OUT)/armeabi-v7a/lib$(NAME).so

else ifeq ($(ARCH),arm64)

ABI := arm64-v8a
TARGET := aarch64-linux-android$(API)

CXXFLAGS := \
	-std=c++17 \
	-fPIC \
	-O2 \
	-Wall \
	-Wextra \
	-Wpedantic \
	--target=$(TARGET) \
	-march=armv8-a

LDFLAGS := \
	--target=$(TARGET)

ARMCall_LIB := \
	$(OUT)/arm64-v8a/lib$(NAME).so

else

$(error Invalid ARCH='$(ARCH)'. Use ARCH=arm32 or ARCH=arm64)

endif

# ============================================================
# Test Build Directory
# ============================================================

TEST_BUILD := $(OBJ)/$(ABI)

# ============================================================
# Test Sources
# ============================================================

TEST_MAIN_SRC := $(SRC)/main.cpp
TEST_LIB_SRC := $(SRC)/test_lib.cpp

# ============================================================
# Test Objects
# ============================================================

TEST_MAIN_OBJ := $(TEST_BUILD)/main.o
TEST_LIB_OBJ := $(TEST_BUILD)/test_lib.o

# ============================================================
# Test Outputs
# ============================================================

TEST_BIN := $(TEST_BUILD)/test
TEST_LIB := $(TEST_BUILD)/libtest.so

# ARMCall is copied beside the executable.
#
# This allows:
#
#     -Wl,-rpath,'$$ORIGIN'
#
# to find libarmcall.so at runtime.
# ============================================================

TEST_ARMCall_LIB := \
	$(TEST_BUILD)/lib$(NAME).so

# ============================================================
# Default Target
# ============================================================

.PHONY: all

all: test

# ============================================================
# Build Test
# ============================================================

.PHONY: test

test: $(TEST_BIN) $(TEST_LIB)
	@echo
	@echo "============================================================"
	@echo " ARMCall Test Build Complete"
	@echo "============================================================"
	@echo " Architecture : $(ARCH)"
	@echo " ABI          : $(ABI)"
	@echo " Target       : $(TARGET)"
	@echo
	@echo " Test binary  : $(TEST_BIN)"
	@echo " Test library : $(TEST_LIB)"
	@echo " ARMCall      : $(TEST_ARMCall_LIB)"
	@echo "============================================================"
	@echo

# ============================================================
# ARMCall Library Copy
# ============================================================

$(TEST_ARMCall_LIB): $(ARMCall_LIB)
	@mkdir -p $(dir $@)
	@echo "  COPY    $@"
	cp $< $@

# ============================================================
# Test Shared Library
# ============================================================

$(TEST_LIB): $(TEST_LIB_OBJ)
	@mkdir -p $(dir $@)
	@echo "  LD      $@"

	$(CLANGXX) \
		$(LDFLAGS) \
		-shared \
		-fPIC \
		-Wl,--gc-sections \
		-o $@ \
		$^

# ============================================================
# Test Library Object
# ============================================================

$(TEST_LIB_OBJ): $(TEST_LIB_SRC)
	@mkdir -p $(dir $@)
	@echo "  CXX     $<"

	$(CLANGXX) \
		$(CXXFLAGS) \
		$(INCLUDES) \
		-MMD \
		-MP \
		-c $< \
		-o $@

# ============================================================
# Test Executable
# ============================================================

$(TEST_BIN): $(TEST_MAIN_OBJ) $(TEST_ARMCall_LIB)
	@mkdir -p $(dir $@)
	@echo "  LD      $@"

	$(CLANGXX) \
		$(CXXFLAGS) \
		$(LDFLAGS) \
		-o $@ \
		$(TEST_MAIN_OBJ) \
		-L$(TEST_BUILD) \
		-l$(NAME) \
		-ldl \
		-Wl,-rpath,'$$ORIGIN'

# ============================================================
# Test Main Object
# ============================================================

$(TEST_MAIN_OBJ): $(TEST_MAIN_SRC)
	@mkdir -p $(dir $@)
	@echo "  CXX     $<"

	$(CLANGXX) \
		$(CXXFLAGS) \
		$(INCLUDES) \
		-MMD \
		-MP \
		-c $< \
		-o $@

# ============================================================
# Dependencies
# ============================================================

DEPS := \
	$(TEST_MAIN_OBJ:.o=.d) \
	$(TEST_LIB_OBJ:.o=.d)

-include $(DEPS)

# ============================================================
# Run Test
#
# Requires:
#
#     adb
#     Android ARM32/ARM64 device
#
# The following files are pushed together:
#
#     test
#     libtest.so
#     libarmcall.so
#
# ============================================================

ADB ?= adb

REMOTE_DIR := /data/local/tmp/armcall-test

.PHONY: run

run: test
	@echo
	@echo "============================================================"
	@echo " Running ARMCall Test"
	@echo "============================================================"
	@echo " Architecture : $(ARCH)"
	@echo " ABI          : $(ABI)"
	@echo "============================================================"
	@echo

	$(ADB) shell rm -rf $(REMOTE_DIR)

	$(ADB) shell mkdir -p $(REMOTE_DIR)

	$(ADB) push \
		$(TEST_BIN) \
		$(REMOTE_DIR)/test

	$(ADB) push \
		$(TEST_LIB) \
		$(REMOTE_DIR)/libtest.so

	$(ADB) push \
		$(TEST_ARMCall_LIB) \
		$(REMOTE_DIR)/lib$(NAME).so

	$(ADB) shell chmod 755 \
		$(REMOTE_DIR)/test

	$(ADB) shell \
		"cd $(REMOTE_DIR) && ./test"

# ============================================================
# ARM32 Test
# ============================================================

.PHONY: arm32

arm32:
	$(MAKE) ARCH=arm32 test

# ============================================================
# ARM64 Test
# ============================================================

.PHONY: arm64

arm64:
	$(MAKE) ARCH=arm64 test

# ============================================================
# Run ARM32 Test
# ============================================================

.PHONY: run-arm32

run-arm32:
	$(MAKE) ARCH=arm32 run

# ============================================================
# Run ARM64 Test
# ============================================================

.PHONY: run-arm64

run-arm64:
	$(MAKE) ARCH=arm64 run

# ============================================================
# Strip Test Libraries
# ============================================================

.PHONY: strip

strip: test
	@echo "  STRIP   $(TEST_LIB)"
	$(LLVM_STRIP) --strip-unneeded $(TEST_LIB)

	@echo "  STRIP   $(TEST_ARMCall_LIB)"
	$(LLVM_STRIP) --strip-unneeded $(TEST_ARMCall_LIB)

# ============================================================
# Clean
# ============================================================

.PHONY: clean

clean:
	@echo "  CLEAN   test"
	rm -rf $(BUILD)/test

# ============================================================
# Information
# ============================================================

.PHONY: info

info:
	@echo
	@echo "============================================================"
	@echo " ARMCall Test Configuration"
	@echo "============================================================"
	@echo " Name          : $(NAME)"
	@echo " API           : $(API)"
	@echo " Architecture  : $(ARCH)"
	@echo " ABI           : $(ABI)"
	@echo " Target        : $(TARGET)"
	@echo " Build         : $(TEST_BUILD)"
	@echo " ARMCall       : $(ARMCall_LIB)"
	@echo " Test binary   : $(TEST_BIN)"
	@echo " Test library  : $(TEST_LIB)"
	@echo "============================================================"
	@echo

# ============================================================
# Help
# ============================================================

.PHONY: help

help:
	@echo
	@echo "ARMCall Tests"
	@echo
	@echo "Build:"
	@echo "  make arm32              Build ARM32 test"
	@echo "  make arm64              Build ARM64 test"
	@echo "  make ARCH=arm32         Build ARM32 test"
	@echo "  make ARCH=arm64         Build ARM64 test"
	@echo
	@echo "Run:"
	@echo "  make run-arm32          Build + run ARM32 test"
	@echo "  make run-arm64          Build + run ARM64 test"
	@echo "  make ARCH=arm32 run     Build + run ARM32 test"
	@echo "  make ARCH=arm64 run     Build + run ARM64 test"
	@echo
	@echo "Other:"
	@echo "  make info               Show configuration"
	@echo "  make strip              Strip test libraries"
	@echo "  make clean              Remove test build"
	@echo