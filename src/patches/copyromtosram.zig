const std = @import("std");
const builtin = @import("builtin");
const patchutil = @import("patchutil.zig");
const variables = @import("variables");

export fn copyromtosram() callconv(.Naked) noreturn {
    const SRAM = patchutil.SRAM;

    // Set stack to our own address
    asm volatile (
        \\
        :
        : [_] "{sp}" (variables.userStack),
        : "sp"
    );

    // Copy file from ROM to SRAM
    const ROMB = @intToPtr([*]align(1) volatile u8, variables.saveLocation);

    var i: usize = 0;
    while (true) {
        const a = ROMB[i];
        const b = ROMB[i];
        if (a != b) continue;

        SRAM[i] = a;
        i += 1;
        if (i == variables.saveSize) {
            break;
        }
    }

    patchutil.jumpTo(variables.originalEntry);

    unreachable;
}
