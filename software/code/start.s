.section .reset.text, "ax"
.global _start
_start:
    .cfi_startproc
    .cfi_undefined ra
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, _estack
    add s0, sp, zero
    jal zero, ResetHandler
    .cfi_endproc
    .end
