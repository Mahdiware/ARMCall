#include "armcall.h"
#include <iostream>
#include <dlfcn.h>
#include <stdexcept>

using namespace armcall;

void* ResolveSymbol(void* handle, const char* symbol) {
  void* func = dlsym(handle, symbol);
  if (!func) {
    throw std::runtime_error(std::string("dlsym failed: ") + dlerror());
  }
  return func;
}

int main() {
  try {
    void* handle = dlopen("./libtest.so", RTLD_LAZY);
    if (!handle) {
      throw std::runtime_error(std::string("dlopen failed: ") + dlerror());
    }

    // 1. double calculate(double a, int b)
    void* fn_calc = ResolveSymbol(handle, "calculate");
    Signature sig_calc {
      Type::Double,
      { Type::Double, Type::Int32 }
    };
    Value res1 = RuntimeCall(fn_calc, sig_calc, { Value::Double(2.5), Value::Int32(4) });
    std::cout << "calculate(2.5, 4) = " << res1.f64 << std::endl;

    // 2. int64_t sum64(int64_t a, int64_t b)
    void* fn_sum64 = ResolveSymbol(handle, "sum64");
    Signature sig_sum {
      Type::Int64,
      { Type::Int64, Type::Int64 }
    };
    Value res2 = RuntimeCall(fn_sum64, sig_sum, { Value::Int64(10000000000), Value::Int64(25) });
    std::cout << "sum64(10B, 25) = " << res2.i64 << std::endl;

    // 3. int many_args(a,b,c,d,e,f) -> forces stack usage
    void* fn_many = ResolveSymbol(handle, "many_args");
    Signature sig_many {
      Type::Int32,
      { Type::Int32, Type::Int32, Type::Int32, Type::Int32, Type::Int32, Type::Int32 }
    };
    Value res3 = RuntimeCall(fn_many, sig_many, {
      Value::Int32(1), Value::Int32(2), Value::Int32(3), 
      Value::Int32(4), Value::Int32(5), Value::Int32(6)
    });
    std::cout << "many_args(1..6) = " << res3.i32 << std::endl;

  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
  }
  return 0;
}