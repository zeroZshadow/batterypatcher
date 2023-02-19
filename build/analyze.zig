const std = @import("std");

pub fn analyzeRom(rom_path: []const u8) !void {
    const romInputFile = try std.fs.cwd().openFile(rom_path, .{});
    defer romInputFile.close();
    var buffer = std.io.bufferedReader(romInputFile.reader());
    var reader = buffer.reader();

    const wordSize = @sizeOf(u32);
    var position: usize = 0;
    while (true) {
        // Find start of empty space
        const startOfBlock = position;
        position += wordSize;
        const word = reader.readIntLittle(u32) catch |err| switch (err) {
            error.EndOfStream => return,
            else => return err,
        };
        if (word != 0xffffffff) continue;

        while (true) : (position += wordSize) {
            // Find end of empty space
            const word2 = reader.readIntLittle(u32) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            if (word2 != 0xffffffff) break;
        }

        const blockSize = position - startOfBlock;
        // Skip blocks smaller than 18 ARM instructions
        if (blockSize > 18 * wordSize) {
            std.log.debug("Found block at {} size {}", .{ startOfBlock, blockSize });
        }
    }
}
