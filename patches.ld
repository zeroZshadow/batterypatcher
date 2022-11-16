MEMORY {
    rom	: ORIGIN = 0x00000000, LENGTH = 32M
}

ENTRY(__text_start)

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(armv4t)

__text_start = ORIGIN(rom);

SECTIONS
{
    . = __text_start;

    .text :
    {
        . = ALIGN(4);
        KEEP(*(.text))
    } >rom

    .data : {
        . = ALIGN(4);
        KEEP(*(.data*))
    } >rom

    .rodata : {
        . = ALIGN(4);
        KEEP(*(.rodata*))
    } >rom

    /DISCARD/ : {
        *(.ARM.exidx*)
        *(.data.rel.ro)
    }

    __text_end = .;
}
