const std = @import("std");
const builtin = @import("builtin");
const patchutil = @import("patchutil.zig");
const variables = @import("variables");

const Variables = extern struct {
    FlashID_A_Method: u32 = 0xd1adbeef,
    FlashID_B_Method: u32 = 0xd2adbeef,
    FlashID_Unknown_Method: u32 = 0xd3adbeef,
};

export fn testpatch() callconv(.Naked) noreturn {
    const ROM = patchutil.ROM;

    // Reset Flash card
    ROM[0] = 0xff;
    ROM[0] = 0x50;

    // Request Flash ID
    ROM[0] = 0x90;

    const flashid: u16 = ROM[1];
    switch (flashid) {
        0x8902, 0x8904, 0x887d, 0x88b0 => {
            ROM[0] = 0xff;

            patchutil.jumpTo(variables.FlashID_B_Method);
        },
        0x8815, 0x8810, 0x88e0, 0x8813, 0x88c0, 0x88f0, 0x8812, 0x8816, 0x8855, 0x8857, 0x88c6, 0x88c4, 0x88d0 => {
            ROM[0] = 0xff;

            patchutil.jumpTo(variables.FlashID_A_Method);
        },
        else => {
            ROM[0] = 0xf0;

            patchutil.jumpTo(variables.FlashID_Unknown_Method);
        },
    }

    unreachable;
}
