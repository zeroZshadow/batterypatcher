const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.intowram);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{
    .WRAMExecutionBlock = 12,
    .BlockStart = 8,
    .BlockEnd = 4,
};

comptime {
    if (builtin.cpu.arch == .thumb) {
        const thunk = struct {
            fn patch() callconv(.Naked) noreturn {
                asm volatile (
                    \\.arm
                    \\.cpu arm7tdmi
                    \\
                    \\//IntoWRAM
                    \\ldr r0, #WRAMExecutionBlock
                    \\ldr r1, #BlockStart
                    \\ldr r2, #BlockEnd
                    \\
                    \\CopyLoop:                     //Copy data from Start to End into WRAM
                    \\ldr r3, [r1, #0x0]
                    \\str r1, [r0, #0x0]
                    \\add r1, r1, 0x4
                    \\add r0, r1, 0x4
                    \\cmp r1, r2
                    \\bne CopyLoop
                    \\
                    \\ldr r0, #WRAMExecutionBlock   //Jump to copied data
                    \\bx  r0
                    \\
                    \\// DATA
                    \\WRAMExecutionBlock:
                    \\.word 0x0203fc10              //Last 1007 bytes of WRAM 256KBytes
                    \\BlockStart:
                    \\.word 0xDEADBEEF
                    \\BlockEnd:
                    \\.word 0xDEADBEEF
                );

                unreachable;
            }
        };

        @export(thunk.patch, .{ .name = "intowram", .section = ".text" });
    }
}
