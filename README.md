ARMCall

Runtime native function invocation for Android ARM32 and ARM64.

ARMCall is a small C/C++ library for invoking native functions at runtime using architecture-specific ARM calling-convention stubs.

It targets Android's "armeabi-v7a" and "arm64-v8a" ABIs and provides a common runtime interface while keeping the low-level ABI implementation in architecture-specific assembly.

«Status: Experimental / research»

---

Overview

Calling a native function dynamically is more complicated than simply branching to its address.

The caller must construct the machine state expected by the target function:

- General-purpose argument registers
- Floating-point/SIMD argument registers
- Stack arguments
- Stack alignment
- Return-value registers
- Callee-saved registers
- Architecture-specific calling conventions

ARMCall provides the low-level mechanism required to construct that state and transfer control to a target function.

The project currently supports:

Architecture| Android ABI| Instruction set
ARM32| "armeabi-v7a"| AArch32 / Thumb-2
ARM64| "arm64-v8a"| AArch64

These are the Android NDK's corresponding ARM ABIs.

---

Design

ARMCall intentionally keeps the architecture implementations in the same source files.

src/
├── runtime.cpp
├── abi.cpp
└── call.S

Instead of maintaining:

abi_arm32.cpp
abi_arm64.cpp

call_arm32.S
call_arm64.S

ARMCall uses compile-time architecture detection:

#if defined(__aarch64__)

    // AArch64

#elif defined(__arm__)

    // AArch32

#endif

The same approach is used by "call.S".

#if defined(__aarch64__)

    // AArch64 implementation

#elif defined(__arm__)

    // AArch32 implementation

#endif

This keeps the public runtime layer shared while allowing the generated machine code to be completely architecture-specific.

---

How It Works

At a high level:

                    Runtime
                       │
                       │
                 CallContext
                       │
                       ▼
                ┌─────────────┐
                │   abi.cpp   │
                └──────┬──────┘
                       │
             ┌─────────┴─────────┐
             │                   │
          ARM32                 ARM64
         __arm__            __aarch64__
             │                   │
             ▼                   ▼
       arm32_invoke         arm64_invoke
             │                   │
             └─────────┬─────────┘
                       │
                       ▼
                    call.S
                       │
                       ▼
                Target function

The runtime prepares a call context containing the values that need to be placed into the target ABI's argument locations.

The assembly stub then:

1. Saves the registers required by the stub.
2. Reads the runtime call context.
3. Constructs the required stack argument area.
4. Loads the appropriate argument registers.
5. Transfers control to the target function.
6. Collects the return registers.
7. Restores the caller's state.
8. Returns to the runtime.

---

ARM64

ARM64 uses the AArch64 procedure call standard.

The AArch64 PCS defines how separately compiled or assembled routines communicate through an externally visible interface.

ARMCall's ARM64 implementation works with the AArch64 register file and its argument/return-value conventions.

The general-purpose argument registers are primarily:

x0 - x7

Floating-point/SIMD arguments use the appropriate SIMD/FP registers.

Additional arguments can be represented in the stack argument area.

The implementation is contained in:

src/call.S

and selected with:

#if defined(__aarch64__)

---

ARM32

ARM32 uses the Arm 32-bit procedure call standard and supports the Arm/Thumb instruction sets.

For Android, "armeabi-v7a" is the 32-bit ARM ABI and includes Thumb-2 and Neon support. The Android NDK uses "-mfloat-abi=softfp" for this ABI's floating-point calling convention.

ARMCall's ARM32 implementation uses the core argument registers:

r0 - r3

with additional arguments represented in the stack argument area.

The assembly implementation is selected with:

#if defined(__arm__)

---

Why "call.S"?

The assembly source intentionally uses an uppercase ".S" extension:

call.S

rather than:

call.s

This allows the assembly source to pass through the C preprocessor.

That makes architecture selection possible directly inside the assembly source:

#if defined(__aarch64__)

    // ARM64 assembly

#elif defined(__arm__)

    // ARM32 assembly

#endif

As a result, the same "call.S" source can produce two completely different object files.

---

Build System

ARMCall uses a small GNU Make build system and Clang from the Android NDK.

The build targets are:

aarch64-linux-android
armv7a-linux-androideabi

The Android NDK identifies these corresponding ABIs as:

arm64-v8a
armeabi-v7a

---

Requirements

- Android NDK
- Clang / Clang++
- GNU Make
- LLVM binutils ("llvm-strip")
- Android API level 21 or newer by default

The Makefile uses Clang's cross-compilation support rather than requiring separate compiler installations for ARM32 and ARM64.

---

Building

Build both architectures:

make

Build only ARM64:

make arm64

Build only ARM32:

make arm32

Clean the build directory:

make clean

Strip the resulting libraries:

make strip

Display build configuration:

make info

---

Android API Level

The default API level is:

21

It can be overridden from the command line:

make API=24

or:

make API=29

The API level becomes part of the Clang target triple.

For example:

aarch64-linux-android24
armv7a-linux-androideabi24

---

Build Output

Running:

make

produces:

build/
└── lib/
    ├── arm64-v8a/
    │   └── libarmcall.so
    │
    └── armeabi-v7a/
        └── libarmcall.so

The architecture-specific object files are also kept separate:

build/
└── obj/
    ├── arm64/
    │   ├── runtime.o
    │   ├── abi.o
    │   └── call.o
    │
    └── arm32/
        ├── runtime.o
        ├── abi.o
        └── call.o

This separation is important because "abi.cpp" and "call.S" are compiled independently for each architecture.

---

Example Build

$ make

Expected structure:

build/lib/arm64-v8a/libarmcall.so
build/lib/armeabi-v7a/libarmcall.so

The same source files:

src/abi.cpp
src/call.S

are compiled once for each target.

Conceptually:

                  abi.cpp
                 /       \
                /         \
        ARM32 compiler   ARM64 compiler
             │               │
             ▼               ▼
        arm32/abi.o     arm64/abi.o


                  call.S
                 /      \
                /        \
        ARM32 compiler  ARM64 compiler
             │              │
             ▼              ▼
       arm32/call.o   arm64/call.o

---

Runtime Model

ARMCall is designed around a runtime call context.

Conceptually, a context contains information such as:

CallContext
├── General-purpose arguments
├── Floating-point arguments
├── Stack argument buffer
└── Stack argument size

The architecture-specific stub consumes this context and converts it into the machine state required by the target ABI.

A corresponding result structure can hold values returned by the target:

CallResult
├── Integer/general-purpose result
└── Floating-point result

The exact representation is implementation-specific and may evolve as additional ABI cases are supported.

---

Important: Function Signatures

ARMCall does not automatically determine the complete type signature of an arbitrary function from its address.

For a correct invocation, the runtime must know enough information about the target function to construct the appropriate call context.

For example, these are not equivalent:

int function(int);

and:

int function(double);

Although both have one argument, the ABI may place those arguments in different register classes.

Likewise:

void function(int, int, int, int, int);

requires different handling from:

void function(int, int);

because additional arguments may cross from registers into the stack argument area.

Therefore, callers must provide ABI-compatible argument metadata.

---

ABI Correctness

ARMCall operates directly at the calling-convention level.

Correctness depends on maintaining the requirements of the target ABI, including:

- Argument classification
- Register allocation
- Stack layout
- Stack alignment
- Register preservation
- Return-value classification
- Floating-point/SIMD handling
- Architecture-specific instruction state

The Arm ABI specifications define the contract between callers and callees, including the obligations around machine state and register preservation.

---

Project Structure

ARMCall/
│
├── src/
│   ├── runtime.cpp       # Runtime layer
│   ├── abi.cpp           # Architecture-independent ABI interface
│   └── call.S            # ARM32/ARM64 call stubs
│
├── Makefile
├── LICENSE
└── README.md

Generated files are intentionally kept under:

build/

and should normally not be committed to the repository.

---

Design Principles

Single Source

ARM32 and ARM64 share the same high-level source files.

Explicit ABI Handling

The library does not attempt to hide the underlying calling convention from the implementation.

Minimal Runtime Overhead

The core mechanism is implemented close to the machine-code level.

Architecture Isolation

Each architecture gets its own object files and final shared library.

Portable Build Interface

The same Makefile can produce both Android ARM ABIs.

---

Limitations

ARMCall is intentionally low-level and currently does not attempt to solve every possible native ABI case.

Potential limitations include:

- Complex aggregate arguments
- Homogeneous floating-point aggregates
- Variadic functions
- Large structure returns
- Complex C++ ABI types
- Exception propagation
- Advanced SIMD/vector argument cases
- Architecture-specific ABI extensions

Support for these cases requires additional classification and runtime metadata.

---

Safety

An invalid call context can corrupt the process state.

Incorrect:

- Argument types
- Argument sizes
- Register assignments
- Stack layout
- Stack alignment
- Return-value interpretation

can result in undefined behavior or a native crash.

ARMCall should therefore be treated as a low-level ABI interface, not as a type-safe replacement for normal C/C++ calls.

---

Use Cases

ARMCall is intended for legitimate low-level software development and research, including:

- Runtime systems
- Native interoperability
- Foreign-function interfaces
- ABI experimentation
- Binary analysis
- Reverse-engineering research
- Instrumentation
- Debugging
- Emulator/runtime development
- Compiler and language-runtime experiments
- Native Android development

---

Non-Goals

ARMCall is not intended to be:

- A general-purpose reflection system
- A C++ type introspection system
- A complete foreign-function interface for every platform
- A replacement for normal static function calls
- A universal function-signature inference engine

Its scope is deliberately narrower: constructing and performing native ARM calls from runtime call information.

---

Roadmap

- [ ] Improve integer argument handling
- [ ] Improve floating-point argument handling
- [ ] Support additional return-value classifications
- [ ] Improve aggregate/struct argument support
- [ ] Improve variadic-call support
- [ ] Add ABI validation
- [ ] Add automated ARM32 tests
- [ ] Add automated ARM64 tests
- [ ] Add benchmark suite
- [ ] Add C API
- [ ] Add higher-level C++ API
- [ ] Add Android example project
- [ ] Expand documentation for ABI edge cases

---

Contributing

Contributions are welcome.

When modifying architecture-specific code, keep ARM32 and ARM64 implementations clearly separated:

#if defined(__aarch64__)

    // AArch64

#elif defined(__arm__)

    // AArch32

#endif

For assembly:

#if defined(__aarch64__)

    // AArch64

#elif defined(__arm__)

    // AArch32

#endif

Changes should be tested against both supported targets:

arm64-v8a
armeabi-v7a

Before submitting a pull request, verify that:

make clean
make

successfully produces both shared libraries.

---

License

ARMCall is distributed under the MIT License.

See ""LICENSE"" (LICENSE) for the complete license text.

---

Author

Mohamed Abdifitaah Jama

ARMCall is developed as a low-level ARM runtime and ABI experimentation project.

---

References

- "Android NDK — Android ABIs" (https://developer.android.com/ndk/guides/abis)
- "Arm ABI — Application Binary Interface for the Arm Architecture" (https://github.com/ARM-software/abi-aa)
- "AAPCS32 — Procedure Call Standard for the Arm 32-bit Architecture" (https://github.com/ARM-software/abi-aa/blob/main/aapcs32/aapcs32.rst)
- "AAPCS64 — Procedure Call Standard for the Arm 64-bit Architecture" (https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst)

The ARM ABI repository contains the current AAPCS32/AAPCS64 specifications and related ABI documents.

---

Status

ARM32 / ARM64 support: Experimental

Platform: Android

Language: C / C++ / ARM Assembly

Build system: GNU Make

Toolchain: LLVM/Clang

Supported ABIs: "armeabi-v7a", "arm64-v8a"