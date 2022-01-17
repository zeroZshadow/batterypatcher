const std = @import("std");
const builtin = @import("builtin");
const gba = @import("gba.zig");
const patching = @import("patching.zig");
const patches = @import("patches");

const PatchType = patching.PatchWriter(dataOffsets, patches.intowram);

pub const writePatch = PatchType.writePatch;

const dataOffsets = .{};

comptime {
    if (builtin.cpu.arch == .thumb) {
        const thunk = struct {
            fn patch() callconv(.Naked) noreturn {
                asm volatile (
                    \\.arm
                    \\.cpu arm7tdmi
                    \\
                    \\ BRB 5 MIN BREAK
                );

                unreachable;
            }
        };

        @export(thunk.patch, .{ .name = "intowram", .section = ".text" });
    }
}
