const std = @import("std");
const builtin = @import("builtin");

export fn detectflashchip3() callconv(.Naked) noreturn {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\
        \\mov        r3, #0x8000000
        \\ldr        r4, #CMD_ResetFlash
        \\ldr        r5, #CMD_RequestFlashID
        \\ldr        r6, #ID_5152
        \\strh       r4, [r3, #0x0]
        \\add        r2, r3, #0x154
        \\strh       r5, [r2, #0x0]
        \\add        r2, r3, #0x40
        \\ldrh       r0, [r2, #0x0]
        \\cmp        r0, r6
        \\beq        FlashID_5152A
        \\strh       r4, [r3, #0x0]
        \\add        r2, r3, #0xaa
        \\strh       r5, [r2, #0x0]
        \\add        r2, r3, #0x20
        \\ldrh       r0, [r2, #0x0]
        \\cmp        r0, r6
        \\beq        FlashID_5152B
        \\mov        r1, #0xf0
        \\strh       r1, [r3, #0x0]
        \\ldr        r1, #FlashID_227d_Method
        //\\subs     r1, r1, #0x1a // Originally the above adress was something FlashID_227d_Method + 26, and then 26 was substracted. I am confused.
        \\bx         r1
        \\
        \\FlashID_5152A:
        \\strh       r4, [r3, #0x0]
        \\mov        r0, #0x0
        \\ldr        r1, #FlashID_5152A_Method
        \\bx         r1
        \\
        \\FlashID_5152B:
        \\strh       r4, [r3, #0x0]
        \\mov        r0, #0x4
        \\ldr        r1, #FlashID_5152B_Method
        \\bx         r1
        \\
        // DATA
        \\CMD_ResetFlash:
        \\.word     0x0000F0F0
        \\CMD_RequestFlashID:
        \\.word     0x00009898
        \\ID_5152:
        \\.word     0x00005152
        \\FlashID_227d_Method:
        \\.word     0xDEADBEEF
        \\FlashID_5152A_Method:
        \\.word     0xDEADBEEF
        \\FlashID_5152B_Method:
        \\.word     0xDEADBEEF
    );

    unreachable;
}
