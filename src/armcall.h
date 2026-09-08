#pragma once
#include <cstdint>
#include <vector>

namespace armcall {

enum class Type {
  Void,
  Int32,
  UInt32,
  Int64,
  UInt64,
  Pointer,
  Float,
  Double
};

union Value {
  int32_t i32;
  uint32_t u32;
  int64_t i64;
  uint64_t u64;
  void* ptr;
  float f32;
  double f64;

  static Value Int32(int32_t v) { Value val; val.i32 = v; return val; }
  static Value UInt32(uint32_t v) { Value val; val.u32 = v; return val; }
  static Value Int64(int64_t v) { Value val; val.i64 = v; return val; }
  static Value UInt64(uint64_t v) { Value val; val.u64 = v; return val; }
  static Value Pointer(void* v) { Value val; val.ptr = v; return val; }
  static Value Float(float v) { Value val; val.f32 = v; return val; }
  static Value Double(double v) { Value val; val.f64 = v; return val; }
};

struct Signature {
  Type return_type;
  std::vector<Type> args;
};

// Main entry point
Value RuntimeCall(void* function_address, const Signature& sig, const std::vector<Value>& args);

} // namespace armstub