const std = @import("std");
const patches = @import("patches");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const myallocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Load ROM into memory / Double the size
    const romInputFile = try std.fs.cwd().openFile("./testrom.gba", .{});
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

    // Patch game entry point to jump to patch location
    patchEntryJump(romBuffer, codeOffset);

    // Write SRAM patch
    writePatch(romBuffer, "intowram", codeOffset);

    // Write Game entry/exit patch

    // Write back rom
    const romOutputFile = try std.fs.cwd().createFile("./patched-testrom.gba", .{});
    defer romOutputFile.close();

    try romOutputFile.writeAll(romBuffer);
}

fn patchEntryJump(rom: []u8, jumpOffset: u32) void {
    // Calculate and write new offset jump for patch
    const op = (((jumpOffset - 8) / 4) & 0x00FFFFFF) | 0xEA000000;
    std.mem.writeIntSlice(u32, rom[0..4], op, .Little);
}

fn writePatch(rom: []u8, comptime patchName: []const u8, writeOffset: u32) void {
    const patch = @embedFile("../zig-out/patches/intowram.bin"); //@field(patches, patchName));

    std.log.debug("Applying patch \"{s}\" at offset {} patch.len {}", .{ patchName, writeOffset, patch.len });
    std.mem.copy(u8, rom[writeOffset .. writeOffset + patch.len], patch);
}
