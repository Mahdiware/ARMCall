#include <cstdint>

extern "C" {

int add(int a, int b) {
  return a + b;
}

int add_float(int a, float b) {
  return a + (int)b;
}

double calculate(double a, int b) {
  return a * b;
}

int64_t sum64(int64_t a, int64_t b) {
  return a + b;
}

int many_args(int a, int b, int c, int d, int e, int f) {
  // a-d are in r0-r3. e, f are pushed to stack!
  return a + b + c + d + e + f;
}

}