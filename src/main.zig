const std = @import("std");
const copyromtosram = @import("patches/copyromtosram.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const myallocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Load ROM into memory / Double the size
    const romInputFile = try std.fs.cwd().openFile("./testrom.gba", .{ .read = true });
    defer romInputFile.close();

    const romStat = try romInputFile.stat();
    const romBuffer = try myallocator.alloc(u8, romStat.size * 2);
    defer myallocator.free(romBuffer);

    std.mem.set(u8, romBuffer, 0xff);

    const readBytes = try romInputFile.readAll(romBuffer);
    std.debug.assert(readBytes == romStat.size);

    // Calculate offset / save location / save size
    const baseAddress = 0x08000000;
    const codeOffset = 0x08800000 - baseAddress;

    // Write SRAM patch
    const patchValues = .{ .originalEntry = 0x080000c0, .saveSize = 65536, .savelocation = 0x08840000 };
    copyromtosram.writePatch(patchValues, romBuffer, codeOffset);

    // Write Game entry/exit patch

    // Write back rom
    const romOutputFile = try std.fs.cwd().createFile("./patched-testrom.gba", .{});
    defer romOutputFile.close();

    try romOutputFile.writeAll(romBuffer);
}
