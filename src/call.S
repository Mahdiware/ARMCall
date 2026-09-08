#if defined(__aarch64__)

.text
.align 2
.global arm64_invoke
.type arm64_invoke, %function

// void arm64_invoke(void* func [x0], const CallContext64* ctx [x1], CallResult64* out_result [x2])
arm64_invoke:
  // Prologue: Save frame pointer, link register, and callee-saved registers we use
  stp x29, x30, [sp, #-32]!
  mov x29, sp
  stp x19, x20, [sp, #16]

  mov x19, x0   // x19 = func
  mov x20, x2   // x20 = out_result

  // Context is at x1. Extract stack parameters.
  // CallContext64 layout: x[8] (64), v[8] (64), stack_ptr (8), stack_size (8)
  ldr x9, [x1, #128]  // ctx->stack_ptr
  ldr x10, [x1, #136] // ctx->stack_size

  cbz x10, .Lload_regs_64

  // AAPCS64 requires SP to be 16-byte aligned at all times
  add x11, x10, #15
  and x11, x11, #~15
  sub sp, sp, x11

  // Copy stack arguments (8 bytes at a time)
  mov x12, sp
.Lcopy_loop_64:
  cbz x10, .Lload_regs_64
  ldr x13, [x9], #8
  str x13, [x12], #8
  sub x10, x10, #8
  b .Lcopy_loop_64

.Lload_regs_64:
  // Load V registers (offset 64)
  add x9, x1, #64
  ldp d0, d1, [x9]
  ldp d2, d3, [x9, #16]
  ldp d4, d5, [x9, #32]
  ldp d6, d7, [x9, #48]

  // Load X registers (offset 0)
  ldp x0, x1, [x1]
  ldp x2, x3, [x1, #16]
  ldp x4, x5, [x1, #32]
  ldp x6, x7, [x1, #48]

  // Call target
  blr x19

  // Store return values (x0 and d0) into out_result
  str x0, [x20]
  str d0, [x20, #8]

  // Epilogue
  mov sp, x29
  ldp x19, x20, [sp, #16]
  ldp x29, x30, [sp], #32
  ret

#elif defined(__arm__)

.syntax unified
.text
.align 2
.global arm32_invoke
.type arm32_invoke, %function
.thumb
.thumb_func

// void arm32_invoke(void* func [r0], const CallContext32* ctx [r1], CallResult32* out_result [r2])
arm32_invoke:
  // Push 10 registers (r4-r11, r12, lr) -> 40 bytes pushed.
  // 40 is a multiple of 8, preserving exact 8-byte stack alignment.
  push {r4-r11, r12, lr}
  
  // Use r11 (fp) as frame anchor to reliably restore SP regardless of stack allocations
  mov r11, sp

  // Preserve function arguments in callee-saved registers
  mov r4, r0 // target function
  mov r5, r1 // ctx pointer
  mov r6, r2 // out_result pointer

  // CallContext32 offset layout:
  // r[4]: 0..15 | stack_ptr: 16 | stack_size: 20
  ldr r7, [r5, #16] // ctx->stack_ptr
  ldr r8, [r5, #20] // ctx->stack_size

  cmp r8, #0
  beq .Lload_regs_32

  // Round up stack allocation size to an 8-byte boundary
  add r9, r8, #7
  bic r9, r9, #7
  sub sp, sp, r9

  // Copy stack arguments low-to-high
  mov r10, sp
.Lcopy_loop_32:
  cmp r8, #0
  ble .Lload_regs_32
  ldr r12, [r7], #4
  str r12, [r10], #4
  sub r8, r8, #4
  b .Lcopy_loop_32

.Lload_regs_32:
  // Load target registers r0-r3 from ctx->r
  ldmia r5, {r0-r3}

  // Call target function (blx handles ARM/Thumb switching automatically via Bit 0)
  blx r4

  // Store return value registers (r0, r1) into CallResult32
  stmia r6, {r0, r1}

  // Restore original stack pointer from frame pointer
  mov sp, r11

  // Pop saved registers and return
  pop {r4-r11, r12, pc}

#endif