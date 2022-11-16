const std = @import("std");
const gba = @import("src/gba.zig");

fn addPatch(b: *std.build.Builder, patcher_options: *std.build.OptionsStep, name: []const u8, path: []const u8, args: anytype) void {
    const bin = b.addExecutable(name, path);
    bin.setTarget(gba.Target);
    bin.setBuildMode(.ReleaseSmall);
    //bin.emit_llvm_ir = .emit;
    bin.setLinkerScriptPath(std.build.FileSource{ .path = "patches.ld" });

    const variables = b.addOptions();
    switch (@typeInfo(@TypeOf(args))) {
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                variables.addOption(field.field_type, field.name, @field(args, field.name));
            }
        },
        else => @compileError("Only structs are supported for patch arguments"),
    }
    bin.addOptions("variables", variables);

    const rawOutput = bin.installRaw(b.fmt("{s}.bin", .{name}), .{
        .dest_dir = std.build.InstallDir{ .custom = "patches" },
    });

    patcher_options.addOptionFileSource(name, rawOutput.getOutputSource());
}

pub fn build(b: *std.build.Builder) !void {
    b.setPreferredReleaseMode(.Debug);
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Patches
    const patch_options = b.addOptions();
    addPatch(b, patch_options, "copyromtosram", "src/patches/copyromtosram.zig", .{
        .userStack = 0x03007f00,
        .saveLocation = 0x08840000,
        .saveSize = 0x00010000,
        .originalEntry = 0x080000C0,
    });
    //const sramtoromPatch = addPatch(b, "sramtorom", "src/patches/sramtorom.zig");
    //const intowramPatch = addPatch(b, "intowram", "src/patches/intowram.zig");

    //const detect1Patch = addPatch(b, "detectflashchip1", "src/patches/detectflashchip1.zig");
    //const detect2Patch = addPatch(b, "detectflashchip2", "src/patches/detectflashchip2.zig");
    //const detect3Patch = addPatch(b, "detectflashchip3", "src/patches/detectflashchip3.zig");

    //const typeIntelBufferPatch = addPatch(b, "type_intel_buffer", "src/patches/type_intel_buffer.zig");

    //addPatch(b, patch_options, "testpatch", "src/patches/testpatch.zig");

    // Tool
    const exe = b.addExecutable("batterypatcher", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addOptions("patches", patch_options);
    exe.main_pkg_path = ".";
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&exe.step);
}
