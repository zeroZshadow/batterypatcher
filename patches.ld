MEMORY {
    rom	: ORIGIN = 0x08000000, LENGTH = 32M
}

ENTRY(__text_start)

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)

__text_start = ORIGIN(rom);

SECTIONS
{
    . = __text_start;

    .text :
    {
        KEEP(*(.text))
        . ALIGN(2);
    } >rom

    /DISCARD/ : {
        *(.ARM.exidx*)
    }

    __text_end = .;
}
