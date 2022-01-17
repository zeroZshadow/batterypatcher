const std = @import("std");
const builtin = @import("builtin");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.detectflashchip1);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{};

comptime {
    if (builtin.cpu.arch == .thumb) {
        const thunk = struct {
            fn patch() callconv(.Naked) noreturn {
                asm volatile (
                    \\.arm
                    \\.cpu arm7tdmi
                    \\.thumb
                    \\
                );

                unreachable;
            }
        };

        @export(thunk.patch, .{ .name = "detectflashchip1", .section = ".text" });
    }
}
