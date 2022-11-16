const std = @import("std");
const builtin = @import("builtin");

export fn detectflashchip1() callconv(.Naked) noreturn {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\
        // Base ROM address
        \\mov        r3, #0x8000000
        \\
        // Reset Flash
        \\mov        r1, #0xff
        \\strh       r1, [r3,#0x0]
        // Reset Flash Registers
        \\mov        r1, #0x50
        \\strh       r1, [r3, #0x0]
        // Request Flash ID
        \\mov        r1, #0x90
        \\strh       r1, [r3, #0x0]
        // Read Flash ID
        \\add        r3, r3, #0x2
        \\ldrh       r1, [r3, #0x0] // Why not just offset 2 here?
        \\subs       r3, r3, #0x2
        \\
        // Switch on Flash ID
        \\mov        r2, #0x8900
        \\orr        r0, r2, #0x2
        \\cmp        r1, r0
        \\beq        FlashID_A
        \\orr        r0, r2, #0x4
        \\cmp        r1, r0
        \\beq        FlashID_A
        \\mov        r2, #0x8800
        \\orr        r0, r2, #0x15
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x10
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xe
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x7d
        \\cmp        r1, r0
        \\beq        FlashID_A
        \\orr        r0, r2, #0xb0
        \\cmp        r1, r0
        \\beq        FlashID_A
        \\orr        r0, r2, #0x13
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xc
        \\cmp        r1,r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xf
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x12
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x16
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x55
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0x57
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xc6
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xc4
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xd
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\orr        r0, r2, #0xe
        \\cmp        r1, r0
        \\beq        FlashID_B
        \\mov        r1, #0xf0
        \\strh       r1, [r3, #0x0]
        \\ldr        r1, #FlashID_Unknown_Method
        \\bx         r1
        \\
        \\FlashID_B:    // Reset flash and jump
        \\mov        r1, #0xff
        \\strh       r1, [r3, #0x0]
        \\ldr        r1, #FlashID_B_Method
        \\bx         r1
        \\
        \\FlashID_A:    // Reset flash and jump
        \\mov        r1, #0xff
        \\strh       r1, [r3, #0x0]
        \\ldr        r1, #FlashID_A_Method
        \\bx         r1
        \\
        // DATA
        \\FlashID_Unknown_Method:
        \\.word 0xDEADBEEF
        \\FlashID_B_Method:
        \\.word 0xDEADBEEF
        \\FlashID_A_Method:
        \\.word 0xDEADBEEF
    );

    unreachable;
}
