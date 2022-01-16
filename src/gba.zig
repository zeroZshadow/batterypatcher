const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

pub const Target = blk: {
    var target = CrossTarget{ .cpu_arch = std.Target.Cpu.Arch.thumb, .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi }, .os_tag = .freestanding };
    target.cpu_features_add.addFeature(@enumToInt(std.Target.arm.Feature.thumb_mode));
    break :blk target;
};
