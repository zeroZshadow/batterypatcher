const std = @import("std");
const builtin = @import("builtin");
const patchutil = @import("patchutil.zig");
const variables = @import("variables");

export fn intowram() callconv(.Naked) noreturn {
    // asm volatile (
    //     \\.arm
    //     \\.cpu arm7tdmi
    //     \\
    //     \\//IntoWRAM
    //     \\ldr r0, #WRAMExecutionBlock
    //     \\ldr r1, #BlockStart
    //     \\ldr r2, #BlockEnd
    //     \\
    //     \\CopyLoop:                     //Copy data from Start to End into WRAM
    //     \\ldr r3, [r1, #0x0]
    //     \\str r1, [r0, #0x0]
    //     \\add r1, r1, 0x4
    //     \\add r0, r1, 0x4
    //     \\cmp r1, r2
    //     \\bne CopyLoop
    //     \\
    //     \\ldr r0, #WRAMExecutionBlock   //Jump to copied data
    //     \\bx  r0
    //     \\
    //     \\// DATA
    //     \\WRAMExecutionBlock:
    //     \\.word 0x0203fc10              //Last 1007 bytes of WRAM 256KBytes
    //     \\BlockStart:
    //     \\.word 0xDEADBEEF
    //     \\BlockEnd:
    //     \\.word 0xDEADBEEF
    // );

    const WRAMExecutionBlock = @intToPtr([*]align(2) volatile u16, variables.WRAMExecutionBlock);
    const BlockStart = @intToPtr([*]align(2) volatile u16, variables.BlockStart);

    var i: usize = 0;
    while (true) {
        WRAMExecutionBlock[i] = BlockStart[i];
        i += 1;
        if (i == variables.BlockLength) {
            break;
        }
    }

    patchutil.jumpTo(variables.WRAMExecutionBlock);

    unreachable;
}
