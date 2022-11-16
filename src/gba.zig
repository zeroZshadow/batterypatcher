const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

pub const Target = blk: {
    var target = CrossTarget{ .cpu_arch = std.Target.Cpu.Arch.arm, .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi }, .os_tag = .freestanding };
    break :blk target;
};
