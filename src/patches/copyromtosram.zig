const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.copyromtosram);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{
    .savelocation = 12,
    .saveSize = 8,
    .originalEntry = 4,
};

comptime {
    if (builtin.cpu.arch == .thumb) {
        const thunk = struct {
            fn patch() callconv(.Naked) noreturn {
                asm volatile (
                    \\.arm
                    \\.cpu arm7tdmi
                    \\
                    \\ldr sp, #UserStack        //Set stack to SP_usr
                    \\ldr r0, #ROMSaveLocation  //r0 = ROM Save start
                    \\mov r1, #0xe000000        //r1 = SRAM start
                    \\ldr r2, #SaveSize         //r2 = Save size
                    \\CopyByteToSRAM:
                    \\ldrb r3, [r0, #0x0]
                    \\ldrb r4, [r0, #0x0]
                    \\cmp r3, r4                //Avoid read errors from rom?
                    \\bne CopyByteToSRAM
                    \\strb r3, [r1, #0x0]       //Write byte to SRAM
                    \\add r1, r1, #0x1
                    \\add r0, r0, #0x1
                    \\subs r2, r2, #0x1
                    \\bne CopyByteToSRAM
                    \\ldr r0, #OriginalEntry    //Jump to Original game entry
                    \\bx r0
                    \\UserStack:
                    \\  .word 0x03007f00
                    \\ROMSaveLocation:
                    \\  .word 0xDEADBEEF
                    \\SaveSize:
                    \\ .word 0xDEADBEEF
                    \\OriginalEntry:
                    \\  .word 0xDEADBEEF
                );

                unreachable;
            }
        };

        @export(thunk.patch, .{ .name = "copyromtosram", .section = ".text" });
    }
}
