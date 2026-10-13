.text
    .globl _start

_start:
    addi  x1, x0, 5
    addi  x2, x0, 10
    add   x3, x1, x2
    add   x4, x3, x3
    sub   x5, x4, x1
    addi  x6, x0, 1
    addi  x6, x6, 1
    addi  x6, x6, 1
    addi  x7, x0, 100
    addi  x7, x7, 1
    add   x8, x7, x7
    sw    x3, 128(x0)
    sw    x4, 132(x0)
    sw    x5, 136(x0)
    sw    x6, 140(x0)
    sw    x8, 144(x0)
    addi  x0, x0, 55
    add   x9, x0, x0
    addi  x10, x0, 9
    add   x11, x0, x10
    sw    x9, 148(x0)
    sw    x11, 152(x0)
    sw    x0, 156(x0)
    addi  x13, x0, 77
    sw    x13, 0(x0)
    addi  x14, x0, 88
    addi  x15, x0, 16
    sw    x14, 4(x0)
    sw    x13, 0(x15)
    lw    x16, 0(x0)
    add   x17, x16, x16
    lw    x18, 4(x0)
    addi  x19, x0, 1
    add   x20, x18, x19
    lw    x21, 0(x0)
    addi  x0, x0, 0
    addi  x0, x0, 0
    add   x22, x21, x21
    lw    x23, 4(x0)
    sw    x23, 8(x0)
    addi  x24, x0, 20
    sw    x24, 12(x0)
    lw    x25, 12(x0)
    sw    x13, 0(x25)
    lw    x26, 20(x0)
    addi  x27, x26, 1
    lw    x28, 0(x0)
    addi  x29, x0, 28
    lw    x28, 0(x0)
    lui   x30, 0xE0
    lw    x0, 0(x0)
    add   x2, x0, x0
    sw    x17, 160(x0)
    sw    x20, 164(x0)
    sw    x22, 168(x0)
    sw    x27, 172(x0)
    sw    x26, 176(x0)
    sw    x29, 180(x0)
    sw    x30, 184(x0)
    sw    x2, 188(x0)

    lw    x3, 0(x0)
    beq   x3, x3, D1
    addi  x31, x0, -1
    sw    x31, 508(x0)

D1:
    addi  x1, x0, 5
    addi  x2, x0, 5
    beq   x1, x2, E1
    addi  x31, x0, -1
    sw    x31, 508(x0)

E1:
    bne   x1, x2, E2
    addi  x3, x0, 1
E2:
    addi  x4, x0, -1
    blt   x4, x0, E3
    addi  x31, x0, -1
    sw    x31, 508(x0)

E3:
    bltu  x4, x0, E4
    addi  x5, x0, 1

E4:
    bgeu  x4, x0, E5
    addi  x31, x0, -1
    sw    x31, 508(x0)

E5:
    bge   x0, x4, E6
    addi  x31, x0, -1
    sw    x31, 508(x0)

E6:
    bge   x4, x0, E7
    addi  x6, x0, 1

E7:
    blt   x0, x4, E8
    addi  x7, x0, 1

E8:
    addi  x8, x0, 3
    addi  x9, x0, 0

LOOP:
    addi  x9, x9, 2
    addi  x8, x8, -1
    bne   x8, x0, LOOP

    sw    x3, 192(x0)
    sw    x5, 196(x0)
    sw    x6, 200(x0)
    sw    x7, 204(x0)
    sw    x9, 208(x0)
    sw    x8, 212(x0)

    jal   x10, F1
    addi  x31, x0, -1
    sw    x31, 508(x0)

F1:
    sw    x10, 216(x0)
    addi  x11, x0, 0x1a9       # F2 + 1 (odd on purpose: jalr must clear bit 0)
    jalr  x12, 0(x11)
    addi  x31, x0, -1
    sw    x31, 508(x0)

F2:
    sw    x12, 220(x0)
    jal   x1, FUNC
    sw    x20, 224(x0)
    jal   x0, AFTER

FUNC:
    addi  x20, x0, 42
    jalr  x0, 0(x1)
    addi  x31, x0, -1
    sw    x31, 508(x0)

AFTER:
    jal   x0, G1
    addi  x31, x0, -1
    sw    x31, 508(x0)

G1:
    jal   x0, G2
    addi  x31, x0, -1
    sw    x31, 508(x0)

G2:
    addi  x21, x0, 1
    sw    x21, 228(x0)

    lui   x1, 0x12345
    addi  x1, x1, 0x678
    auipc x2, 1

    addi  x3, x0, -8
    srai  x4, x3, 1
    srli  x5, x3, 28
    slli  x6, x3, 2

    slt   x7, x3, x0
    sltu  x8, x3, x0
    slti  x9, x3, -7
    sltiu x10, x3, -7

    xori  x11, x1, -1
    andi  x12, x1, 255
    ori   x13, x0, 0x555

    sub   x14, x0, x3
    add   x15, x1, x3
    sll   x16, x14, x5
    srl   x17, x3, x5
    sra   x18, x3, x5
    xor   x19, x1, x1
    and   x20, x1, x11
    or    x21, x1, x11

    sw    x1, 232(x0)
    sw    x2, 236(x0)
    sw    x4, 240(x0)
    sw    x5, 244(x0)
    sw    x6, 248(x0)
    sw    x7, 252(x0)
    sw    x8, 256(x0)
    sw    x9, 260(x0)
    sw    x10, 264(x0)
    sw    x11, 268(x0)
    sw    x12, 272(x0)
    sw    x13, 276(x0)
    sw    x14, 280(x0)
    sw    x15, 284(x0)
    sw    x16, 288(x0)
    sw    x17, 292(x0)
    sw    x18, 296(x0)
    sw    x19, 300(x0)
    sw    x20, 304(x0)
    sw    x21, 308(x0)

END:
    jal   x0, END