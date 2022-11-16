const std = @import("std");
const builtin = @import("builtin");

export fn detectflashchip2() callconv(.Naked) noreturn {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\
        \\mov        r3, #0x8000000
        \\mov        r1, #0xf0
        \\strh       r1, [r0, #0x0] // BUG? Pretty sure this should be storing in r3
        \\add        r2, r3, #0xaa0
        \\add        r2, r2, #0xa
        \\mov        r1, #0xa9
        \\strh       r1, [r2, #0x0]
        \\add        r2, r3, #0x550
        \\add        r2, r2, #0x5
        \\mov        r1, #0x56
        \\strh       r1, [r2, #0x0]
        \\add        r2, r3, #0xaa0
        \\add        r2, r2, #0xa
        \\mov        r1, #0x90
        \\strh       r1, [r2, #0x0]
        \\add        r2, r3, #0x2
        \\ldrh       r1, [r2, #0x0]
        \\mov        r2, #0x2200
        \\add        r2, r2, #0x7d
        \\cmp        r1, r2
        \\beq        FlashID_0x227d
        \\mov        r1, #0xf0
        \\strh       r1, [r3,#0x0]
        \\ldr        r1, #FlashID_Unknown_Method
        \\bx         r1
        \\
        \\FlashID_0x227d:
        \\mov        r1, #0xf0
        \\strh       r1, [r3, #0x0]
        \\ldr        r1, #FlashID_Type227d_Method
        \\bx         r1
        \\
        // DATA
        \\FlashID_Unknown_Method:
        \\.word 0xDEADBEEF
        \\FlashID_Type227d_Method:
        \\.word 0xDEADBEEF
    );

    unreachable;
}
