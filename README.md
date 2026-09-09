ARMCall

Runtime native function invocation for Android ARM32 and ARM64.

ARMCall is a lightweight C/C++ library for invoking native functions at runtime using architecture-specific ARM calling-convention implementations.

It targets Android's "armeabi-v7a" and "arm64-v8a" ABIs while providing a common runtime interface across both architectures.

«Status: Experimental / Research»

---

Overview

Calling a native function dynamically requires more than transferring execution to its address. The caller must construct the machine state expected by the target function according to the platform's ABI.

ARMCall provides the low-level runtime needed to:

- Prepare function arguments
- Handle register and stack-based arguments
- Support integer and floating-point values
- Maintain required stack alignment
- Invoke the target function
- Retrieve return values
- Preserve the required machine state

The architecture-specific implementation is written in ARM assembly, while the higher-level runtime interface is shared.

Supported Architectures

Architecture| Android ABI| Instruction Set
ARM32| "armeabi-v7a"| AArch32 / Thumb-2
ARM64| "arm64-v8a"| AArch64

---

How It Works

ARMCall uses a runtime call context to describe the arguments and other information required for a function invocation.

At a high level:

                 Runtime
                    │
                    ▼
              CallContext
                    │
                    ▼
              ABI Interface
                    │
          ┌─────────┴─────────┐
          │                   │
        ARM32               ARM64
       AArch32              AArch64
          │                   │
          └─────────┬─────────┘
                    ▼
             Assembly Stub
                    │
                    ▼
             Target Function
                    │
                    ▼
               CallResult

The runtime prepares the call context, and the architecture-specific assembly stub converts that information into the machine state required by the target ABI.

---

Architecture Support

ARM64

ARM64 follows the AArch64 Procedure Call Standard (AAPCS64).

ARMCall supports the primary general-purpose argument registers and floating-point/SIMD argument registers defined by the ABI, with additional arguments represented through the stack argument area where required.

ARM32

ARM32 follows the AArch32 Procedure Call Standard (AAPCS32) and supports the Android "armeabi-v7a" ABI.

The implementation uses the standard ARM32 argument registers and stack argument area according to the target ABI.

---

Build System

ARMCall uses GNU Make together with the Android NDK's Clang toolchain.

Supported targets:

aarch64-linux-android
armv7a-linux-androideabi

These correspond to:

arm64-v8a
armeabi-v7a

The same source tree can be used to build both architectures.

---

Requirements

- Android NDK
- Clang / Clang++
- GNU Make
- LLVM binutils
- Android API level 21 or newer

No separate ARM32 and ARM64 compiler installations are required.

---

Building

Build both architectures:

make

Build only ARM64:

make arm64

Build only ARM32:

make arm32

Clean build files:

make clean

Strip generated libraries:

make strip

Display build configuration:

make info

---

Android API Level

The default Android API level is 21.

It can be overridden when building:

make API=24

or:

make API=29

The selected API level is passed to Clang through the Android target configuration.

---

Build Output

A successful build produces:
```
build/
├── lib/
│   ├── arm64-v8a/
│   │   └── libarmcall.so
│   │
│   └── armeabi-v7a/
│       └── libarmcall.so
│
└── obj/
    ├── arm64/
    └── arm32/
```
The generated files under "build/" should normally not be committed to the repository.

---

Runtime Model

ARMCall is based around two main concepts:

"CallContext"

Describes the information required to perform a native function call, including:

- General-purpose arguments
- Floating-point arguments
- Stack arguments
- Stack argument size
- Other ABI-specific information

"CallResult"

Contains values returned by the target function.

The exact representation may evolve as ARMCall gains support for additional ABI cases.

---

Function Signatures

ARMCall does not automatically determine the complete type signature of an arbitrary function from its address.

The caller must provide sufficient information for ARMCall to construct a valid ABI-compatible call.

For example:

int function(int);

and:

int function(double);

have different ABI requirements even though both functions receive a single argument.

Similarly, functions with more arguments may require part of their argument list to be placed in the stack argument area.

Correct type and ABI metadata is therefore essential for safe invocation.

---

ABI Correctness

ARMCall operates directly at the calling-convention level. Correctness depends on accurately following the target architecture's ABI.

Important areas include:

- Argument classification
- Register allocation
- Stack layout
- Stack alignment
- Register preservation
- Return-value classification
- Floating-point/SIMD handling
- Architecture-specific ABI rules

For supported architectures, ARMCall follows the relevant Arm procedure call standards.

---

Project Structure
```
ARMCall/
├── src/
│   ├── runtime.cpp
│   ├── abi.cpp
│   └── call.S
│
├── Makefile
├── LICENSE
└── README.md
```
Source Files

File| Purpose
"runtime.cpp"| Runtime interface and call management
"abi.cpp"| ABI-level call preparation
"call.S"| Architecture-specific assembly invocation
"Makefile"| Build configuration

The architecture-specific implementation is selected automatically during compilation.

---

Design Goals

Lightweight

ARMCall focuses on the core mechanism required for runtime native invocation without introducing a large runtime dependency.

Shared Interface

ARM32 and ARM64 use the same high-level runtime interface.

Architecture-Specific Implementation

Low-level calling-convention details remain isolated in architecture-specific code.

Low Overhead

The invocation mechanism operates close to the machine-code level to minimize unnecessary runtime overhead.

Simple Build

A single Makefile can build both Android ARM architectures.

---

Limitations

ARMCall is currently experimental and does not attempt to cover every possible native ABI case.

Some limitations may include:

- Complex aggregate arguments
- Homogeneous floating-point aggregates
- Variadic functions
- Large structure returns
- Complex C++ ABI types
- Exception propagation
- Advanced SIMD/vector arguments
- Architecture-specific ABI extensions

Support for these cases requires additional ABI classification and runtime metadata.

---

Safety

ARMCall is a low-level ABI interface. Incorrect call metadata can result in undefined behavior, memory corruption, or a native crash.

Particular care must be taken with:

- Argument types
- Argument sizes
- Register assignments
- Stack layout
- Stack alignment
- Return-value interpretation

ARMCall should therefore not be considered a type-safe replacement for ordinary C/C++ function calls.

Use it only when the target function's ABI and signature are known.

---

Use Cases

ARMCall is intended for legitimate low-level software development and research, including:

- Runtime systems
- Foreign-function interfaces
- Native interoperability
- ABI experimentation
- Binary analysis
- Reverse-engineering research
- Instrumentation
- Debugging
- Emulator and runtime development
- Compiler and language-runtime experiments
- Native Android development

---

Contributing

Contributions are welcome.

When modifying ARM-specific code, ensure that changes remain compatible with both supported architectures:

arm64-v8a
armeabi-v7a

Before submitting a change, verify that both targets build successfully:

make clean
make

Architecture-specific changes should be tested on the corresponding Android ABI whenever possible.

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

---

Status

Component| Status
ARM32| Experimental
ARM64| Experimental
Platform| Android
Languages| C / C++ / ARM Assembly
Build System| GNU Make
Toolchain| LLVM / Clang
ABIs| "armeabi-v7a", "arm64-v8a"
