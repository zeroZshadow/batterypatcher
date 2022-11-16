const std = @import("std");
const builtin = @import("builtin");

// Intel chips, byte by byte
export fn type_intel_single() callconv(.Naked) noreturn {
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\//Entry
        \\mov        r2, #0x84
        \\mov        r2, r2, lsl #0x10
        \\mov        r0, #0x8000000
        \\orr        r2, r2, r0         // r2 = 0x08840000 -> Save location in ROM
        \\bl         FUN_EraseSector
        \\mov        r5, #0xe000000     // r5 = SRAM address
        \\mov        r3, #0x10
        \\mov        r3, r3, lsl #0xc   // r3 = 65536 -> size of save // TODO REPLACE WITH LOAD
        \\bl         FUN_CopySRAMToROM
        \\ldr        r0, #PTR_FUN_RestoreInterruptAndResume // Restore interrupt table and resume game
        \\bx         r0
        \\
        \\// Function
        \\FUN_CopySRAMToROM:
        \\stmdb      sp!, {lr}
        \\
        \\CopyNextWord:
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0]
        \\mov        r0, r0
        \\mov        r0, #0x70
        \\strh       r0, [r2, #0x0]
        \\mov        r0, r0
        \\WaitForReady:
        \\ldrb       r0, [r2, #0x0]
        \\and        r0, r0, #0xff
        \\cmp        r0, #0x80
        \\bne        WaitForReady
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0]
        \\mov        r0, r0
        \\mov        r0, #0x40
        \\strh       r0, [r2, #0x0]
        \\ldrb       r6, [r5, #0x0]
        \\add        r5, r5,#0x1
        \\ldrb       r7, [r5, #0x0]
        \\add        r5, r5, #0x1
        \\orr        r6, r6, r7, lsl #0x8
        \\strh       r6, [r2, #0x0]
        \\WaitForReady2:
        \\ldrb       r0, [r2, #0x0]
        \\and        r0, r0, #0xff
        \\cmp        r0, #0x80
        \\bne        WaitForReady2
        \\add        r2, r2, #0x2
        \\subs       r3, r3, #0x2
        \\bne        CopyNextWord
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0]
        \\ldmia      sp!, {lr}
        \\mov        pc, lr              // Return
        \\
        \\// Function
        \\FUN_EraseSector:
        \\stmdb      sp!, {r2, lr}
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\nop
        \\mov        r0, #0x60
        \\strh       r0, [r2, #0x0] // Command: Clear Block Lock-Bits
        \\nop
        \\mov        r0, #0xd0
        \\strh       r0, [r2, #0x0] // Command: Confirm
        \\nop
        \\mov        r0, #0x90
        \\strh       r0, [r2, #0x0] // Command: Read Identifier Codes?
        \\nop
        \\add        r2, r2, #0x2   // Offset SRAM Address
        \\
        \\WaitForUnlock:
        \\ldrb       r0, [r2, #0x0] // Read codes
        \\and        r0, r0, #0x3   // If (codes & 3) == 0, Block is unlocked
        \\bne        WaitForUnlock
        \\sub        r2, r2, #0x2   // Undo SRAM Offset TODO Use offset in Read Codes?
        \\nop
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\nop
        \\mov        r0, #0x20
        \\strh       r0, [r2, #0x0] // Command: Erase Block
        \\nop
        \\mov        r0, #0xd0
        \\strh       r0, [r2, #0x0] // Command: Confirm
        \\nop
        \\
        \\WaitForErase:
        \\ldrb       r0, [r2, #0x0] // Read Status
        \\and        r0, r0, #0xff  // This seems not needed?
        \\cmp        r0, #0x80      // Status == Ready
        \\bne        WaitForErase
        \\nop
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\ldmia      sp!, {r2, lr}
        \\mov        pc, lr
        \\
        \\PTR_FUN_RestoreInterruptAndResume:
        \\.word      0xDEADBEEF
        \\FUN_WRAM_TypeAEnd:
        \\nop
    );

    unreachable;
}
