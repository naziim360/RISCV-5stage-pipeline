# Pipeline test program

Part of the [5-stage RV32I pipeline project](../README.md).

`prog_pipeline.mem` is a hand-written RV32I program (165 instructions, `0x000` to `0x290`) that tests the pipeline's hazard handling. The testbench runs it, then checks the values the program stored in data memory.

## How to read it

- The program has seven groups, A to G. Each tests one thing, then stores its results with `sw` into data-memory words 32 to 77. The testbench compares every word with its expected value.
- **Poison:** on the wrong path after a taken branch or jump, the program puts two instructions, `addi x31, x0, -1` and `sw x31, 508(x0)`. They must never run. In the listings they appear as `poison`.
- Comments say where an operand comes from:

| Comment | Meaning |
|---|---|
| `MEM` | forwarded from the instruction just before |
| `WB` | forwarded from two instructions before |
| `regfile` | read normally from the register file |
| `STALL` | load-use hazard: the pipeline waits 1 cycle |

| Group | Starts at | Tests |
|---|---|---|
| A | `0x000` | Forwarding between ALU instructions |
| B | `0x040` | Register `x0` |
| C | `0x05c` | Loads, stores and stalls |
| D | `0x0f0` | A load followed by a branch |
| E | `0x100` | Conditional branches |
| F | `0x188` | `jal` and `jalr` |
| G | `0x1e8` | `lui`, `auipc` and all ALU operations |

---

## A. ALU forwarding

**Goal:** an instruction can use a result before it is written back.

```asm
0x000  addi x1, x0, 5
0x004  addi x2, x0, 10
0x008  add  x3, x1, x2      # x1 from WB, x2 from MEM: 15
0x00c  add  x4, x3, x3      # both from MEM: 30
0x010  sub  x5, x4, x1      # x4 from MEM, x1 from regfile: 25
0x014  addi x6, x0, 1
0x018  addi x6, x6, 1       # a chain of dependent instructions
0x01c  addi x6, x6, 1       # x6 = 3
0x020  addi x7, x0, 100
0x024  addi x7, x7, 1       # x7 = 101
0x028  add  x8, x7, x7      # x7 has two writers in flight: the newer one (MEM) must win: 202
0x02c  sw   x3, 128(x0)     # word 32 = 15
0x030  sw   x4, 132(x0)     # word 33 = 30
0x034  sw   x5, 136(x0)     # word 34 = 25
0x038  sw   x6, 140(x0)     # word 35 = 3
0x03c  sw   x8, 144(x0)     # word 36 = 202
```

---

## B. Register x0

**Goal:** `x0` always reads 0. It is never forwarded and never written.

```asm
0x040  addi x0, x0, 55      # writing to x0: must be ignored
0x044  add  x9, x0, x0      # must NOT forward the 55 from MEM: x9 = 0
0x048  addi x10, x0, 9
0x04c  add  x11, x0, x10    # x0 reads 0, x10 from MEM: 9
0x050  sw   x9, 148(x0)     # word 37 = 0
0x054  sw   x11, 152(x0)    # word 38 = 9
0x058  sw   x0, 156(x0)     # word 39 = 0 (x0 was never written)
```

---

## C. Loads, stores and stalls

### C1. Store forwarding

**Goal:** `sw` reads two registers (data and address). Both must be forwarded.

```asm
0x05c  addi x13, x0, 77
0x060  sw   x13, 0(x0)      # data from MEM: mem[0] = 77
0x064  addi x14, x0, 88
0x068  addi x15, x0, 16     # x15 = address of word 4
0x06c  sw   x14, 4(x0)      # data from WB: mem[1] = 88
0x070  sw   x13, 0(x15)     # address from WB: mem[4] = 77
```

### C2. Load-use stalls

**Goal:** a loaded value is not ready for the next instruction, so the pipeline must wait exactly 1 cycle, and only when needed.

```asm
0x074  lw   x16, 0(x0)      # x16 = 77
0x078  add  x17, x16, x16   # STALL 1, then forwarded: 154
0x07c  lw   x18, 4(x0)      # x18 = 88
0x080  addi x19, x0, 1
0x084  add  x20, x18, x19   # one instruction in between: no stall. x18 from WB: 89
0x088  lw   x21, 0(x0)      # x21 = 77
0x08c  addi x0, x0, 0       # nop
0x090  addi x0, x0, 0       # nop
0x094  add  x22, x21, x21   # load is 3 back: from regfile: 154
0x098  lw   x23, 4(x0)      # x23 = 88
0x09c  sw   x23, 8(x0)      # STALL 2 (the loaded value is the store data): mem[2] = 88
```

### C3. Store, then load

**Goal:** a load right after a store to the same address sees the new value, and a loaded pointer can be used as an address.

```asm
0x0a0  addi x24, x0, 20
0x0a4  sw   x24, 12(x0)     # mem[3] = 20 (a pointer)
0x0a8  lw   x25, 12(x0)     # load right after the store, same address: x25 = 20
0x0ac  sw   x13, 0(x25)     # STALL 3 (the loaded value is the address): mem[5] = 77
0x0b0  lw   x26, 20(x0)     # reads what was just stored: 77
0x0b4  addi x27, x26, 1     # STALL 4: 78
```

### C4. No false stalls

**Goal:** some instructions contain bits that look like a register number but are not. They must not cause a stall.

```asm
0x0b8  lw   x28, 0(x0)
0x0bc  addi x29, x0, 28     # the immediate 28 looks like x28, but addi has no rs2: no stall
0x0c0  lw   x28, 0(x0)
0x0c4  lui  x30, 0xE0       # the immediate bits look like x28 in the rs1 field, but lui reads no register: no stall
0x0c8  lw   x0, 0(x0)       # a load into x0
0x0cc  add  x2, x0, x0      # no stall, nothing forwarded: x2 = 0
```

### C5. Results

```asm
0x0d0  sw   x17, 160(x0)    # word 40 = 154
0x0d4  sw   x20, 164(x0)    # word 41 = 89
0x0d8  sw   x22, 168(x0)    # word 42 = 154
0x0dc  sw   x27, 172(x0)    # word 43 = 78
0x0e0  sw   x26, 176(x0)    # word 44 = 77
0x0e4  sw   x29, 180(x0)    # word 45 = 28
0x0e8  sw   x30, 184(x0)    # word 46 = 0x000E0000
0x0ec  sw   x2,  188(x0)    # word 47 = 0
```

---

## D. Load, then branch

**Goal:** a branch reads its registers in EX, so a load right before it is also a load-use case.

```asm
0x0f0  lw   x3, 0(x0)       # x3 = 77
0x0f4  beq  x3, x3, D1      # STALL 5, then taken
0x0f8  poison
```

---

## E. Conditional branches

**Goal:** all six branch types, taken and not taken.

`x4 = 0xFFFFFFFF` is -1 when signed and the largest number when unsigned, so `blt` and `bltu` (and `bge` and `bgeu`) must give opposite answers. A not-taken branch falls through to an `addi` that sets a register to 1. Each of those registers already held another value (`x3` = 77, `x5` = 25, `x6` = 3, `x7` = 101), so a branch that is wrongly taken is caught.

```asm
0x100  addi x1, x0, 5
0x104  addi x2, x0, 5
0x108  beq  x1, x2, E1      # equal: taken
0x10c  poison
0x114  bne  x1, x2, E2      # equal: not taken
0x118  addi x3, x0, 1       # must run: x3 = 1
0x11c  addi x4, x0, -1      # x4 = 0xFFFFFFFF
0x120  blt  x4, x0, E3      # signed, -1 < 0: taken
0x124  poison
0x12c  bltu x4, x0, E4      # unsigned: not taken
0x130  addi x5, x0, 1       # must run: x5 = 1
0x134  bgeu x4, x0, E5      # unsigned: taken
0x138  poison
0x140  bge  x0, x4, E6      # signed, 0 >= -1: taken
0x144  poison
0x14c  bge  x4, x0, E7      # signed, -1 >= 0: not taken
0x150  addi x6, x0, 1       # must run: x6 = 1
0x154  blt  x0, x4, E8      # signed, 0 < -1: not taken
0x158  addi x7, x0, 1       # must run: x7 = 1
```

### Loop

**Goal:** a backward branch that is taken twice, then not taken.

```asm
0x15c  addi x8, x0, 3       # counter = 3
0x160  addi x9, x0, 0       # sum = 0
0x164  addi x9, x9, 2       # LOOP: sum += 2
0x168  addi x8, x8, -1      # counter -= 1
0x16c  bne  x8, x0, LOOP    # x8 from MEM: taken, taken, not taken
```

### Results

```asm
0x170  sw   x3, 192(x0)     # word 48 = 1
0x174  sw   x5, 196(x0)     # word 49 = 1
0x178  sw   x6, 200(x0)     # word 50 = 1
0x17c  sw   x7, 204(x0)     # word 51 = 1
0x180  sw   x9, 208(x0)     # word 52 = 6 (the loop ran 3 times)
0x184  sw   x8, 212(x0)     # word 53 = 0
```

The taken branches store nothing: they are checked by the poison staying untouched.

---

## F. Jumps

**Goal:** `jal` and `jalr` must write the return address and jump to the right place, including when jumps follow each other.

### Jump and link

```asm
0x188  jal  x10, F1         # x10 = 0x18c (return address)
0x18c  poison
0x194  sw   x10, 216(x0)    # F1: reads x10 while jal writes it: word 54 = 0x18c
0x198  addi x11, x0, 0x1a9  # an odd address: F2 + 1
0x19c  jalr x12, 0(x11)     # x11 from MEM; jumps to 0x1a8 (bit 0 cleared); x12 = 0x1a0
0x1a0  poison
0x1a8  sw   x12, 220(x0)    # F2: word 55 = 0x1a0
```

### Call and return

```asm
0x1ac  jal  x1, FUNC        # call: x1 = 0x1b0
0x1b0  sw   x20, 224(x0)    # (runs after the return) word 56 = 42
0x1b4  jal  x0, AFTER       # skip over the function
0x1b8  addi x20, x0, 42     # FUNC: x20 = 42
0x1bc  jalr x0, 0(x1)       # return to 0x1b0
0x1c0  poison
```

### Chained jumps

**Goal:** the instruction at a jump target is itself a jump.

```asm
0x1c8  jal  x0, G1          # AFTER: a jump...
0x1cc  poison
0x1d4  jal  x0, G2          # G1: ...to another jump...
0x1d8  poison
0x1e0  addi x21, x0, 1      # G2: ...to here
0x1e4  sw   x21, 228(x0)    # word 57 = 1
```

---

## G. ALU operations

**Goal:** every R-type and I-type operation once, with values where the signed and unsigned versions, and the arithmetic and logical shifts, give different results.

```asm
0x1e8  lui   x1, 0x12345      # x1 = 0x12345000
0x1ec  addi  x1, x1, 0x678    # x1 = 0x12345678 (from MEM)
0x1f0  auipc x2, 1            # x2 = pc + 0x1000 = 0x000011F0
0x1f4  addi  x3, x0, -8       # x3 = 0xFFFFFFF8
0x1f8  srai  x4, x3, 1        # arithmetic shift right: 0xFFFFFFFC
0x1fc  srli  x5, x3, 28       # logical shift right: 0x0000000F
0x200  slli  x6, x3, 2        # shift left: 0xFFFFFFE0
0x204  slt   x7, x3, x0       # signed: -8 < 0: 1
0x208  sltu  x8, x3, x0       # unsigned: 0xFFFFFFF8 < 0 is false: 0
0x20c  slti  x9, x3, -7       # signed: 1
0x210  sltiu x10, x3, -7      # unsigned: 1
0x214  xori  x11, x1, -1      # NOT x1: 0xEDCBA987
0x218  andi  x12, x1, 0xFF    # 0x00000078
0x21c  ori   x13, x0, 0x555   # 0x00000555
0x220  sub   x14, x0, x3      # 0 - (-8) = 8
0x224  add   x15, x1, x3      # 0x12345670
0x228  sll   x16, x14, x5     # 8 << 15 = 0x00040000 (x14 from WB)
0x22c  srl   x17, x3, x5      # logical: 0x0001FFFF
0x230  sra   x18, x3, x5      # arithmetic: 0xFFFFFFFF
0x234  xor   x19, x1, x1      # 0
0x238  and   x20, x1, x11     # x1 AND NOT x1 = 0
0x23c  or    x21, x1, x11     # x1 OR NOT x1 = 0xFFFFFFFF
```

### Results and halt

```asm
0x240 to 0x28c  sw x1, x2, x4, x5, ... x21    # words 58 to 77, one per register (x3 is not stored)
0x290  jal  x0, 0             # HALT: jumps to itself forever
```

The testbench waits for the PC to reach `0x290`, lets the pipeline drain, then checks everything.

---

## What the testbench counts

- **5 load-use stalls**, marked `STALL 1` to `STALL 5` above (at `0x078`, `0x09c`, `0x0ac`, `0x0b4`, `0x0f4`). Loads that only look dependent (C4, or a load with an instruction in between) must not add any.
- **14 redirects** (taken branches and jumps): `0x0f4`, `0x108`, `0x120`, `0x134`, `0x140`, `0x16c` (twice), `0x188`, `0x19c`, `0x1ac`, `0x1b4`, `0x1bc`, `0x1c8`, `0x1d4`.
- **Poison:** `x31` and word 127 must still be 0, which proves every wrong-path instruction was flushed.
