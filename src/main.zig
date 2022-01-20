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

    // Patch game entry point to jump to patch location
    const originalEntryOffset = patchEntryJump(codeOffset, romBuffer);

    // Write SRAM patch
    const patchValues = .{ .originalEntry = baseAddress + originalEntryOffset, .saveSize = 65536, .savelocation = 0x08840000 };
    copyromtosram.writePatch(patchValues, romBuffer, codeOffset);

    // Write Game entry/exit patch

    // Write back rom
    const romOutputFile = try std.fs.cwd().createFile("./patched-testrom.gba", .{});
    defer romOutputFile.close();

    try romOutputFile.writeAll(romBuffer);
}

fn patchEntryJump(jumpOffset: u32, rom: []u8) u32 {
    // Read and calculate original jump offset
    const originalOffset = (std.mem.readIntSlice(u32, rom[0..4], .Little) & 0x00FFFFFF) * 4 + 8;

    // Calculate and write new offset jump for patch
    const op = (((jumpOffset - 8) / 4) & 0x00FFFFFF) | 0xEA000000;
    std.mem.writeIntSlice(u32, rom[0..4], op, .Little);

    return originalOffset;
}
