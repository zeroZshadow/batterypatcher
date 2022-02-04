const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.testpatch);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{
    .FlashID_A_Method = 12,
    .FlashID_B_Method = 8,
    .FlashID_Unknown_Method = 4,
};

comptime {
    if (builtin.cpu.arch == .arm) {
        const thunk = packed struct {
            const ROM = @intToPtr([*]align(2) volatile u16, 0x08000000);

            export fn patch() linksection(".text") callconv(.Naked) noreturn {
                // Reset Flash card
                ROM[0] = 0xff;
                ROM[0] = 0x50;

                // Request Flash ID
                ROM[0] = 0x90;

                const flashid: u16 = ROM[1];

                switch (flashid) {
                    0x8902, 0x8904, 0x887d, 0x88b0 => {
                        ROM[0] = 0xff;

                        asm volatile (
                            \\ldr r0, #FlashID_B_Method
                            \\bx r0
                        );

                        unreachable;
                    },
                    0x8815, 0x8810, 0x88e0, 0x8813, 0x88c0, 0x88f0, 0x8812, 0x8816, 0x8855, 0x8857, 0x88c6, 0x88c4, 0x88d0 => {
                        ROM[0] = 0xff;

                        asm volatile (
                            \\ldr r0, #FlashID_A_Method
                            \\bx r0
                        );

                        unreachable;
                    },
                    else => {
                        ROM[0] = 0xf0;

                        asm volatile (
                            \\ldr r0, #FlashID_Unknown_Method
                            \\bx r0
                        );

                        unreachable;
                    },
                }

                unreachable;
            }
        };

        asm (
            \\.section .rodata.*
            \\FlashID_Unknown_Method:
            \\.word 0xD1ADBEEF
            \\FlashID_B_Method:
            \\.word 0xD2ADBEEF
            \\FlashID_A_Method:
            \\.word 0xD3ADBEEF
        );

        _ = thunk;
    }
}
