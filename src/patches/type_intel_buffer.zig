const std = @import("std");
const builtin = @import("builtin");

// Intel chips, using write buffer
export fn type_intel_buffer() callconv(.Naked) noreturn {
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
        \\ldr        r0, #PTR_FUN_RestoreInterruptAndResume // Originally this stored the ptr + 1, and subtracted the 1 after load... very weird
        \\bx         r0
        \\
        \\// Function
        \\FUN_CopySRAMToROM:
        \\stmdb      sp!, {lr}
        \\
        \\CopyNextSector:
        \\mov        r0, #0xFF
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\nop
        \\mov        r0, #0x70
        \\strh       r0, [r2, #0x0] // Command: Read Status Register
        \\nop
        \\
        \\WaitForReady:
        \\ldrb       r0, [r2, #0x0] // Read SR
        \\and        r0, r0, #0xFF  // This seems not needed?
        \\cmp        r0, #0x80      // Status == Ready
        \\bne        WaitForReady
        \\
        \\// Prep the sector for writing in chunks for 512 bytes
        \\mov        r0, #0xFF
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\nop
        \\mov        r0, #0xEA
        \\strh       r0, [r2, #0x0] // Command: Write to Buffer
        \\nop
        \\mov        r0, 512        // Amount of words to write (1024 bytes)
        \\sub        r0, r0, 1
        \\strh       r0, [r2, #0x0] // Buffer word count -1 (511)
        \\nop
        \\mov        r1, 512        // r1 = 512
        \\
        \\CopySector:
        \\ldrb       r0, [r5, #0x0]         // Read low byte from SRAM
        \\add        r5, r5, #0x1           // TODO replace with offset read
        \\ldrb       r7, [r5, #0x0]         // Read high byte from SRAM
        \\add        r5, r5, #0x1
        \\orr        r0, r0, r7, lsl #0x8   // Combine to word
        \\strh       r0, [r2, #0x0]         // Write word to buffer
        \\subs       r1, r1, #0x1
        \\beq        CopyCompleted
        \\add        r2, r2, #0x2           // Offset SRAM address
        \\b          CopySector
        \\
        \\CopyCompleted:
        \\mov        r0, #0xd0
        \\strh       r0, [r2, #0x0] // Command: Confirm buffer write
        \\nop
        \\
        \\WaitForReady2:
        \\ldrb       r0, [r2, #0x0] // Read SR
        \\and        r0, r0, #0xff  // This seems not needed?
        \\cmp        r0, #0x80      // Status == Ready
        \\bne        WaitForReady2
        \\
        \\add        r2, r2, #0x2   // Offset SRAM address (Because this was skipped on sector complete)
        \\mov        r4, #0x400     // r4 = 1024
        \\subs       r3, r3, r4     // SizeSize -= 1024 (512 words)
        \\bne        CopyNextSector // Write next sector if there are any bytes remaining
        \\mov        r0, #0xff
        \\strh       r0, [r2, #0x0] // Command: Read Array
        \\ldmia      sp!, {lr}
        \\mov        pc, lr         // Return
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
    );

    unreachable;
}
