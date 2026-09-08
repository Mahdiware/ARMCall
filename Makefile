# ============================================================
# ARMCall
# Runtime native function calling library
# Android ARM32 / ARM64
# ============================================================

NAME        := armcall
BUILD       := build
OUT         := $(BUILD)/lib
OBJ         := $(BUILD)/obj

CLANG       := clang
CLANGXX     := clang++
LLVM_STRIP  := llvm-strip

API         ?= 21

COMMON_CXXFLAGS := \
    -std=c++17 \
    -fPIC \
    -ffunction-sections \
    -fdata-sections \
    -Wall \
    -Wextra \
    -Wpedantic \
    -O2

COMMON_LDFLAGS := \
    -shared \
    -Wl,--gc-sections \
    -Wl,--exclude-libs,ALL

INCLUDES := \
    -Isrc


# ============================================================
# Android ARM64
# ============================================================

A64_TARGET := aarch64-linux-android$(API)

A64_CXX := $(CLANGXX)
A64_CC  := $(CLANG)
A64_AS  := $(CLANG)

A64_CXXFLAGS := \
    $(COMMON_CXXFLAGS) \
    --target=$(A64_TARGET) \
    -march=armv8-a

A64_ASFLAGS := \
    --target=$(A64_TARGET) \
    -march=armv8-a \
    -fPIC

A64_LDFLAGS := \
    $(COMMON_LDFLAGS) \
    --target=$(A64_TARGET)


# ============================================================
# Android ARM32
# ============================================================

ARM_TARGET := armv7a-linux-androideabi$(API)

ARM_CXX := $(CLANGXX)
ARM_CC  := $(CLANG)
ARM_AS  := $(CLANG)

ARM_CXXFLAGS := \
    $(COMMON_CXXFLAGS) \
    --target=$(ARM_TARGET) \
    -march=armv7-a \
    -mthumb \
    -mfloat-abi=softfp

ARM_ASFLAGS := \
    --target=$(ARM_TARGET) \
    -march=armv7-a \
    -mthumb \
    -mfloat-abi=softfp \
    -fPIC

ARM_LDFLAGS := \
    $(COMMON_LDFLAGS) \
    --target=$(ARM_TARGET)


# ============================================================
# Source files
# ============================================================

COMMON_CPP := \
    src/runtime.cpp \
    src/abi.cpp

COMMON_ASM := \
    src/call.S


# ============================================================
# ARM64 object files
# ============================================================

A64_OBJ := \
    $(patsubst src/%.cpp,$(OBJ)/arm64/%.o,$(COMMON_CPP)) \
    $(patsubst src/%.S,$(OBJ)/arm64/%.o,$(COMMON_ASM))


# ============================================================
# ARM32 object files
# ============================================================

ARM_OBJ := \
    $(patsubst src/%.cpp,$(OBJ)/arm32/%.o,$(COMMON_CPP)) \
    $(patsubst src/%.S,$(OBJ)/arm32/%.o,$(COMMON_ASM))


# ============================================================
# Output
# ============================================================

A64_LIB := $(OUT)/arm64-v8a/lib$(NAME).so
ARM_LIB := $(OUT)/armeabi-v7a/lib$(NAME).so


# ============================================================
# Default
# ============================================================

.PHONY: all
all: arm64 arm32


# ============================================================
# ARM64
# ============================================================

.PHONY: arm64

arm64: $(A64_LIB)

$(A64_LIB): $(A64_OBJ)
	@mkdir -p $(dir $@)
	@echo "  LD      $@"
	$(A64_CXX) \
	    $(A64_LDFLAGS) \
	    -o $@ \
	    $^ \
	    -ldl


# ============================================================
# ARM32
# ============================================================

.PHONY: arm32

arm32: $(ARM_LIB)

$(ARM_LIB): $(ARM_OBJ)
	@mkdir -p $(dir $@)
	@echo "  LD      $@"
	$(ARM_CXX) \
	    $(ARM_LDFLAGS) \
	    -o $@ \
	    $^ \
	    -ldl


# ============================================================
# ARM64 C++
# ============================================================

$(OBJ)/arm64/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	@echo "  CXX     [ARM64] $<"
	$(A64_CXX) \
	    $(A64_CXXFLAGS) \
	    $(INCLUDES) \
	    -MMD -MP \
	    -c $< \
	    -o $@


# ============================================================
# ARM64 Assembly
# ============================================================

$(OBJ)/arm64/%.o: src/%.S
	@mkdir -p $(dir $@)
	@echo "  ASM     [ARM64] $<"
	$(A64_AS) \
	    $(A64_ASFLAGS) \
	    $(INCLUDES) \
	    -MMD -MP \
	    -c $< \
	    -o $@


# ============================================================
# ARM32 C++
# ============================================================

$(OBJ)/arm32/%.o: src/%.cpp
	@mkdir -p $(dir $@)
	@echo "  CXX     [ARM32] $<"
	$(ARM_CXX) \
	    $(ARM_CXXFLAGS) \
	    $(INCLUDES) \
	    -MMD -MP \
	    -c $< \
	    -o $@


# ============================================================
# ARM32 Assembly
# ============================================================

$(OBJ)/arm32/%.o: src/%.S
	@mkdir -p $(dir $@)
	@echo "  ASM     [ARM32] $<"
	$(ARM_AS) \
	    $(ARM_ASFLAGS) \
	    $(INCLUDES) \
	    -MMD -MP \
	    -c $< \
	    -o $@


# ============================================================
# Dependencies
# ============================================================

DEPS := \
    $(A64_OBJ:.o=.d) \
    $(ARM_OBJ:.o=.d)

-include $(DEPS)


# ============================================================
# Strip
# ============================================================

.PHONY: strip

strip: arm64 arm32
	@echo "  STRIP   $(A64_LIB)"
	$(LLVM_STRIP) --strip-unneeded $(A64_LIB)

	@echo "  STRIP   $(ARM_LIB)"
	$(LLVM_STRIP) --strip-unneeded $(ARM_LIB)


# ============================================================
# Clean
# ============================================================

.PHONY: clean

clean:
	@echo "  CLEAN"
	rm -rf $(BUILD)


# ============================================================
# Information
# ============================================================

.PHONY: info

info:
	@echo "Name:       $(NAME)"
	@echo "API:        $(API)"
	@echo
	@echo "ARM64:      $(A64_TARGET)"
	@echo "ARM32:      $(ARM_TARGET)"
	@echo
	@echo "ARM64 OBJ:  $(A64_OBJ)"
	@echo "ARM32 OBJ:  $(ARM_OBJ)"
	@echo
	@echo "ARM64 LIB:  $(A64_LIB)"
	@echo "ARM32 LIB:  $(ARM_LIB)"