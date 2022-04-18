const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");
const patchutil = @import("patchutil.zig");

const PatchType = patching.PatchWriter(dataOffsets, patches.testpatch);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{
    .FlashID_A_Method = 12,
    .FlashID_B_Method = 8,
    .FlashID_Unknown_Method = 4,
};

const Variables = packed struct {
    FlashID_A_Method: u32 = 0xd1adbeef,
    FlashID_B_Method: u32 = 0xd2adbeef,
    FlashID_Unknown_Method: u32 = 0xd3adbeef,
};

comptime {
    if (builtin.cpu.arch == .arm) {
        const thunk = packed struct {
            export fn patch() linksection(".text") callconv(.Naked) noreturn {
                const ROM = patchutil.ROM;
                const addresses: Variables = .{};

                // Reset Flash card
                ROM[0] = 0xff;
                ROM[0] = 0x50;

                // Request Flash ID
                ROM[0] = 0x90;

                const flashid: u16 = ROM[1];
                switch (flashid) {
                    0x8902, 0x8904, 0x887d, 0x88b0 => {
                        ROM[0] = 0xff;

                        patchutil.jumpTo(addresses.FlashID_B_Method);
                    },
                    0x8815, 0x8810, 0x88e0, 0x8813, 0x88c0, 0x88f0, 0x8812, 0x8816, 0x8855, 0x8857, 0x88c6, 0x88c4, 0x88d0 => {
                        ROM[0] = 0xff;

                        patchutil.jumpTo(addresses.FlashID_A_Method);
                    },
                    else => {
                        ROM[0] = 0xf0;

                        patchutil.jumpTo(addresses.FlashID_Unknown_Method);
                    },
                }

                unreachable;
            }
        };

        _ = thunk;
    }
}
