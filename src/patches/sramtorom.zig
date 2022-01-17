const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.sramtorom);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{
    .IME = 28,
    .WRAMSaved_IME = 24,
    .IE = 20,
    .WRAMSaved_IE = 16,
    .SoundCNTX = 12,
    .PatchExitThunk = 8,
    .NextMethod = 4,
};

comptime {
    if (builtin.cpu.arch == .thumb) {
        const thunk = struct {
            fn patch() callconv(.Naked) noreturn {
                asm volatile (
                    \\.arm
                    \\.cpu arm7tdmi
                    \\
                    \\// SRAMToROMEntry
                    \\stmdb sp!, {r0-r7}    //Push registers r1 to r7 to stack
                    \\
                    \\// Store current IE into WRAM
                    \\ldr   r0, #IME
                    \\ldr   r1, #WRAMSaved_IME
                    \\ldrh  r2, [r0, #0x0]
                    \\strh  r2, [r1, #0x0]
                    \\
                    \\// Store current IE into WRAM
                    \\ldr   r0, #IE
                    \\ldr   r1, #WRAMSaved_IE
                    \\ldrh  r2, [r0, #0x0]
                    \\strh  r2, [r1], #0x2
                    \\
                    \\// Store control registers into WRAM
                    \\mov   r0, #0x4000000
                    \\ldrh  r2, [r0, #0x82]  //SOUNDCNT_H
                    \\strh  r2, [r1], #0x2   //WRAM_SOUNDCNT_H
                    \\ldrh  r2, [r0, #0x80]  //SOUNDCNT_L
                    \\strh  r2, [r1], #0x2   //WRAM_SOUNDCNT_L
                    \\ldrh  r2, [r0, #0xba]  //DMA0CNT_H
                    \\strh  r2, [r1], #0x2   //WRAM_DMA0CNT_H 
                    \\ldrh  r2, [r0, #0xc6]  //DMA1CNT_H
                    \\strh  r2, [r1], #0x2   //WRAM_DMA1CNT_H 
                    \\ldrh  r2, [r0, #0xd2]  //DMA2CNT_H
                    \\strh  r2, [r1], #0x2   //WRAM_DMA2CNT_H 
                    \\ldrh  r2, [r0, #0xde]  //DMA3CNT_H
                    \\strh  r2, [r1], #0x2   //WRAM_DMA3CNT_H 
                    \\
                    \\// Zero out control registers
                    \\mov   r0, #0x0
                    \\ldr   r1, #IME
                    \\strh  r0, [r1, #0x0]   //IME
                    \\ldr   r1, #IE
                    \\strh  r0, [r1, #0x0]   //IE
                    \\mov   r1, #0x4000000
                    \\strh  r0, [r1, #0x80]  //SOUNDCNT_L
                    \\strh  r0, [r1, #0xba]  //DMA0CNT_H
                    \\strh  r0, [r1, #0xc6]  //DMA1CNT_H
                    \\strh  r0, [r1, #0xd2]  //DMA2CNT_H
                    \\strh  r0, [r1, #0xde]  //DMA3CNT_H
                    \\
                    \\//Set volume to "forbidden" levels
                    \\mov   r0, #0x3
                    \\strh  r0, [r1, #0x82] //SOUNDCNT_H
                    \\ldr   r0, #SoundCNTX
                    \\ldrh  r1, [r0, #0x0]
                    \\// Jump to WRAM Wrapper function
                    \\// Original code does an immediate offset jump of 174 to JUST after this patch, where IntoWRAM_DetectFlash resides. Dont want to hardcode this for now
                    \\ldr   r1, #NextMethod
                    \\bx    r1
                    \\
                    \\// SRAMToROMExit
                    \\
                    \\// Restore IME with value in WRAM
                    \\ldr   r0, #IME
                    \\ldr   r1, #WRAMSaved_IME
                    \\ldrh  r2, [r1, #0x0]
                    \\strh  r2, [r0, #0x0]
                    \\
                    \\// Restore IE with value in WRAM
                    \\ldr   r0, #IE
                    \\ldr   r1, #WRAMSaved_IE
                    \\ldrh  r2, [r1], 0x2
                    \\strh  r2, [r0, #0x0]
                    \\
                    \\// Restore control registers from WRAM
                    \\mov   r0, #0x4000000
                    \\ldrh  r2, [r1], #0x2   //SOUNDCNT_H
                    \\strh  r2, [r0, #0x82]
                    \\ldrh  r2, [r1], #0x2   //SOUNDCNT_L
                    \\strh  r2, [r0, #0x80]
                    \\ldrh  r2, [r1], #0x2    //DMA0CNT_H
                    \\strh  r2, [r0, #0xba]
                    \\ldrh  r2, [r1], #0x2    //DMA1CNT_H
                    \\strh  r2, [r0, #0xc6]
                    \\ldrh  r2, [r1], #0x2    //DMA2CNT_H
                    \\strh  r2, [r0, #0xd2]
                    \\ldrh  r2, [r1], #0x2    //DMA3CNT_H
                    \\strh  r2, [r0, #0xde]
                    \\
                    \\ldmia sp!, {r0-r7} // Pop registers r1 to r7 from stack
                    \\
                    \\ldr   r1, #PatchExitThunk //This overwrites r1. Original code bug?
                    \\bx    r1
                    \\
                    \\// DATA
                    \\IME:
                    \\.word     0x04000208
                    \\WRAMSaved_IME:
                    \\.word     0x0203fc00
                    \\IE:
                    \\.word     0x04000200
                    \\WRAMSaved_IE:
                    \\.word     0x0203fc02
                    \\SoundCNTX:
                    \\.word     0x04000084
                    \\PatchExitThunk:
                    \\.word     0xDEADBEEF  // Add 1 for Thumb
                    \\NextMethod:
                    \\.word     0xDEADBEEF  // Add 1 for Thumb
                );

                unreachable;
            }
        };

        @export(thunk.patch, .{ .name = "sramtorom", .section = ".text" });
    }
}
