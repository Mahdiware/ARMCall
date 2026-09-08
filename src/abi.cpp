#include "armcall.h"
#include <vector>
#include <cstring>

namespace armcall {

#if defined(__aarch64__)

struct CallContext64 {
  uint64_t x[8] = {0};
  double v[8] = {0.0};
  const uint64_t* stack_ptr = nullptr;
  size_t stack_size = 0; // in bytes
};

struct CallResult64 {
  uint64_t x0;
  double d0;
};

extern "C" void arm64_invoke(void* func, const CallContext64* ctx, CallResult64* out_result);

Value CallARM64(void* func, const Signature& sig, const std::vector<Value>& args) {
  CallContext64 ctx;
  std::vector<uint64_t> stack;
  
  int x_idx = 0;
  int v_idx = 0;

  // AAPCS64 Argument Classification
  for (size_t i = 0; i < args.size(); ++i) {
    Type t = sig.args[i];
    const Value& v = args[i];

    if (t == Type::Float || t == Type::Double) {
      if (v_idx < 8) {
        ctx.v[v_idx++] = (t == Type::Float) ? (double)v.f32 : v.f64;
      } else {
        uint64_t stack_val = 0;
        if (t == Type::Float) {
          float f = v.f32;
          __builtin_memcpy(&stack_val, &f, sizeof(float));
        } else {
          __builtin_memcpy(&stack_val, &v.f64, sizeof(double));
        }
        stack.push_back(stack_val);
      }
    } else {
      // Integer / Pointer types
      uint64_t val64 = 0;
      if (t == Type::Int32) val64 = (uint64_t)v.i32;
      else if (t == Type::UInt32) val64 = v.u32;
      else if (t == Type::Int64) val64 = v.i64;
      else if (t == Type::UInt64) val64 = v.u64;
      else if (t == Type::Pointer) val64 = (uint64_t)v.ptr;

      if (x_idx < 8) {
        ctx.x[x_idx++] = val64;
      } else {
        stack.push_back(val64);
      }
    }
  }

  ctx.stack_ptr = stack.data();
  ctx.stack_size = stack.size() * 8; // 8 bytes per slot on AArch64

  CallResult64 res;
  arm64_invoke(func, &ctx, &res);

  Value ret;
  switch (sig.return_type) {
    case Type::Void: break;
    case Type::Int32: ret.i32 = (int32_t)res.x0; break;
    case Type::UInt32: ret.u32 = (uint32_t)res.x0; break;
    case Type::Int64: ret.i64 = (int64_t)res.x0; break;
    case Type::UInt64: ret.u64 = res.x0; break;
    case Type::Pointer: ret.ptr = (void*)res.x0; break;
    case Type::Float: 
      float temp_f; 
      __builtin_memcpy(&temp_f, &res.d0, sizeof(float)); 
      ret.f32 = temp_f; 
      break;
    case Type::Double: ret.f64 = res.d0; break;
  }
  return ret;
}

#elif defined(__arm__)

struct alignas(8) CallContext32 {
  uint32_t r[4] = {0, 0, 0, 0};
  const uint32_t* stack_ptr = nullptr;
  uint32_t stack_size = 0;
};

struct CallResult32 {
  uint32_t r0 = 0;
  uint32_t r1 = 0;
};

extern "C" void arm32_invoke(void* func, const CallContext32* ctx, CallResult32* out_result);

Value CallARM32(void* func, const Signature& sig, const std::vector<Value>& args) {
  CallContext32 ctx;
  std::vector<uint32_t> stack;
  
  int r_idx = 0;

  for (size_t i = 0; i < args.size(); ++i) {
    Type t = sig.args[i];
    const Value& v = args[i];

    bool is_64bit = (t == Type::Int64 || t == Type::UInt64 || t == Type::Double);

    if (is_64bit) {
      uint64_t val64 = 0;
      if (t == Type::Double) std::memcpy(&val64, &v.f64, 8);
      else val64 = v.u64;

      uint32_t low = val64 & 0xFFFFFFFF;
      uint32_t high = static_cast<uint32_t>(val64 >> 32);

      // AAPCS32 requires 64-bit arguments in registers to start on an EVEN register (r0 or r2)
      if (r_idx % 2 != 0) {
        r_idx++; 
      }

      if (r_idx < 4) {
        ctx.r[r_idx++] = low;
        ctx.r[r_idx++] = high;
      } else {
        // AAPCS32 requires 64-bit arguments on stack to be 8-byte aligned
        if (stack.size() % 2 != 0) {
          stack.push_back(0); // Pad with 4 dummy bytes
        }
        stack.push_back(low);
        stack.push_back(high);
      }
    } else {
      uint32_t val32 = 0;
      if (t == Type::Float) std::memcpy(&val32, &v.f32, 4);
      else if (t == Type::Pointer) val32 = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(v.ptr));
      else val32 = v.u32;

      if (r_idx < 4) {
        ctx.r[r_idx++] = val32;
      } else {
        stack.push_back(val32);
      }
    }
  }

  ctx.stack_ptr = stack.empty() ? nullptr : stack.data();
  ctx.stack_size = static_cast<uint32_t>(stack.size() * sizeof(uint32_t));

  CallResult32 res;
  arm32_invoke(func, &ctx, &res);

  Value ret;
  std::memset(&ret, 0, sizeof(ret));

  switch (sig.return_type) {
    case Type::Void: break;
    case Type::Int32: ret.i32 = static_cast<int32_t>(res.r0); break;
    case Type::UInt32: ret.u32 = res.r0; break;
    case Type::Pointer: ret.ptr = reinterpret_cast<void*>(static_cast<uintptr_t>(res.r0)); break;
    case Type::Float: std::memcpy(&ret.f32, &res.r0, 4); break;
    case Type::Int64:
    case Type::UInt64:
    case Type::Double: {
      uint64_t val64 = (static_cast<uint64_t>(res.r1) << 32) | res.r0;
      if (sig.return_type == Type::Double) std::memcpy(&ret.f64, &val64, 8);
      else ret.u64 = val64;
      break;
    }
  }
  return ret;
}

#endif

} // namespace armcall