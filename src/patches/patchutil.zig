const builtin = @import("builtin");

pub const ROM = @intToPtr([*]align(2) volatile u16, 0x08000000);
pub const SRAM = @intToPtr([*]align(1) volatile u8, 0xe0000000);

pub inline fn jumpTo(addr: u32) noreturn {
    if (builtin.cpu.arch == .arm) {
        asm volatile (
            \\bx %[reg]
            :
            : [reg] "r" (addr),
        );

        unreachable;
    }

    unreachable;
}
