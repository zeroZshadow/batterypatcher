pub const ROM = @intToPtr([*]align(2) volatile u16, 0x08000000);

pub inline fn jumpTo(addr: u32) noreturn {
    asm volatile (
        \\bx %[reg]
        :
        : [reg] "r" (addr),
    );

    unreachable;
}
