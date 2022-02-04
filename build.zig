const std = @import("std");
const gba = @import("src/gba.zig");

fn addPatch(b: *std.build.Builder, name: []const u8, path: []const u8) std.build.FileSource {
    const bin = b.addExecutable(name, path);
    bin.setTarget(gba.Target);
    bin.setBuildMode(.ReleaseSmall);
    bin.emit_asm = .emit;
    bin.force_pic = true;
    bin.setLinkerScriptPath(std.build.FileSource{ .path = "patches.ld" });
    return bin.installRaw(b.fmt("{s}.bin", .{name}), .{
        .dest_dir = std.build.InstallDir{ .custom = "patches" },
    }).getOutputSource();
}

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Patches
    const copyromtosramPatch = addPatch(b, "copyromtosram", "src/patches/copyromtosram.zig");
    const sramtoromPatch = addPatch(b, "sramtorom", "src/patches/sramtorom.zig");
    const intowramPatch = addPatch(b, "intowram", "src/patches/intowram.zig");

    const detect1Patch = addPatch(b, "detectflashchip1", "src/patches/detectflashchip1.zig");
    const detect2Patch = addPatch(b, "detectflashchip2", "src/patches/detectflashchip2.zig");
    const detect3Patch = addPatch(b, "detectflashchip3", "src/patches/detectflashchip3.zig");

    const typeAPatch = addPatch(b, "type_a", "src/patches/type_a.zig");

    //const testpatchPatch = addPatch(b, "testpatch", "src/patches/testpatch.zig");

    const patch_options = b.addOptions();
    patch_options.addOptionFileSource("copyromtosram", copyromtosramPatch);
    patch_options.addOptionFileSource("sramtoromPatch", sramtoromPatch);
    patch_options.addOptionFileSource("intowram", intowramPatch);
    patch_options.addOptionFileSource("detect1", detect1Patch);
    patch_options.addOptionFileSource("detect2", detect2Patch);
    patch_options.addOptionFileSource("detect3", detect3Patch);
    patch_options.addOptionFileSource("type_a", typeAPatch);
    //patch_options.addOptionFileSource("testpatch", testpatchPatch);

    // Tool
    const exe = b.addExecutable("batterypatcher", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addOptions("patches", patch_options);
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
