#include "armcall.h"
#include <stdexcept>

namespace armcall {

// Forward declarations for architecture-specific dispatchers
#if defined(__aarch64__)
Value CallARM64(void* func, const Signature& sig, const std::vector<Value>& args);
#elif defined(__arm__)
Value CallARM32(void* func, const Signature& sig, const std::vector<Value>& args);
#endif

Value RuntimeCall(void* function_address, const Signature& sig, const std::vector<Value>& args) {
  if (sig.args.size() != args.size()) {
    throw std::runtime_error("Argument count mismatch");
  }

#if defined(__aarch64__)
  return CallARM64(function_address, sig, args);
#elif defined(__arm__)
  return CallARM32(function_address, sig, args);
#else
  throw std::runtime_error("Unsupported architecture");
#endif
}

} // namespace armcall