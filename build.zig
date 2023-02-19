const std = @import("std");
const gba = @import("src/gba.zig");
const analyze = @import("build/analyze.zig");

fn addPatch(b: *std.build.Builder, patcher_options: *std.build.OptionsStep, name: []const u8, path: []const u8, args: anytype) void {
    const bin = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = path },
        .target = gba.Target,
        .optimize = .ReleaseSmall,
    });
    //bin.emit_llvm_ir = .emit;
    //bin.emit_asm = .emit;
    bin.setLinkerScriptPath(std.build.FileSource{ .path = "patches.ld" });

    const variables = b.addOptions();
    switch (@typeInfo(@TypeOf(args))) {
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                variables.addOption(field.type, field.name, @field(args, field.name));
            }
        },
        else => @compileError("Only structs are supported for patch arguments"),
    }
    bin.addOptions("variables", variables);

    _ = bin.installRaw(b.fmt("{s}.bin", .{name}), .{
        .dest_dir = std.build.InstallDir{ .custom = "patches" },
    });

    patcher_options.addOption([]u8, name, b.fmt("../zig-out/patches/{s}.bin", .{name}));
}

pub fn build(b: *std.build.Builder) !void {
    try analyze.analyzeRom("./testrom.gba");

    // Patches
    const patch_options = b.addOptions();
    addPatch(b, patch_options, "copyromtosram", "src/patches/copyromtosram.zig", .{
        .userStack = 0x03007f00,
        .saveLocation = 0x08840000,
        .saveSize = 0x00010000,
        .originalEntry = 0x080000C0,
    });
    addPatch(b, patch_options, "sramtorom", "src/patches/sramtorom.zig", .{});
    addPatch(b, patch_options, "intowram", "src/patches/intowram.zig", .{
        .WRAMExecutionBlock = 0x0203fc10,
        .BlockStart = 0x08880000,
        .BlockLength = 320,
    });

    addPatch(b, patch_options, "detectflashchip1", "src/patches/detectflashchip1.zig", .{});
    addPatch(b, patch_options, "detectflashchip2", "src/patches/detectflashchip2.zig", .{});
    addPatch(b, patch_options, "detectflashchip3", "src/patches/detectflashchip3.zig", .{});

    addPatch(b, patch_options, "type_intel_buffer", "src/patches/type_intel_buffer.zig", .{});
    addPatch(b, patch_options, "testpatch", "src/patches/testpatch.zig", .{
        .FlashID_A_Method = 0x08840000,
        .FlashID_B_Method = 0x08860000,
        .FlashID_Unknown_Method = 0x08880000,
    });

    // Tool
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "batterypatcher",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
    });
    exe.addOptions("patches", patch_options);

    var cwdbuf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var cwdpath = try std.os.getcwd(&cwdbuf);
    std.log.info("{s}", .{cwdpath});
    exe.setMainPkgPath(cwdpath);
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
