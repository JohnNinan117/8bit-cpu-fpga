
# Custom 8-Bit CPU — Instruction Set Architecture

## 1. Overview

This project implements a custom 8-bit microprocessor in Verilog
on the DE10-Lite FPGA board.

The processor uses a multicycle, non-pipelined architecture
with a fixed 16-bit instruction format.

### CPU Specifications

| Component | Specification |
|---|---|
| Data width | 8 bits |
| Instruction width | 16 bits |
| General-purpose registers | 4 (R0–R3) |
| Register width | 8 bits |
| Program Counter (PC) | 5 bits |
| Instruction memory | 32 x 16-bit ROM |
| Instruction count | 8 |
| Architecture | Multicycle, non-pipelined |
| Memory | Preloaded instruction ROM |
| Output | 8-bit output register |

## 2. Instruction Format

All instructions are 16 bits wide.

| Bits | Field | Description |
|---|---|---|
| 15–12 | Opcode | Selects the instruction |
| 11–10 | Rd | Destination/selected register |
| 9–8 | Rs | Source register |
| 7–0 | Immediate | Constant or branch address |

Instruction layout:

    [ Opcode ][ Rd ][ Rs ][ Immediate ]
      4 bits  2 bits 2 bits   8 bits

Register encoding:

| Register | Encoding |
|---|---|
| R0 | 00 |
| R1 | 01 |
| R2 | 10 |
| R3 | 11 |

Unused instruction fields are encoded as zero.

## 3. Instruction Set

| Instruction | Opcode | Operation |
|---|---|---|
| LDI | 0001 | Rd = immediate |
| ADD | 0010 | Rd = Rd + Rs |
| SUB | 0011 | Rd = Rd - Rs |
| AND | 0100 | Rd = Rd & Rs |
| OR | 0101 | Rd = Rd \| Rs |
| JNZ | 0110 | Jump if Rd != 0 |
| OUT | 0111 | Output = Rd |
| HALT | 1000 | Stop execution |

### LDI — Load Immediate

Loads an 8-bit constant into the selected register.

    LDI R0, 5

Result: R0 = 5

### ADD — Addition

Adds two registers and stores the result in Rd.

    ADD R0, R1

Result: R0 = R0 + R1

### SUB — Subtraction

Subtracts Rs from Rd and stores the result in Rd.

    SUB R0, R1

Result: R0 = R0 - R1

### AND — Bitwise AND

    AND R0, R1

Result: R0 = R0 & R1

### OR — Bitwise OR

    OR R0, R1

Result: R0 = R0 | R1

### JNZ — Jump if Not Zero

Checks the selected register.

    JNZ R0, 4

If R0 != 0, PC becomes 4.

Otherwise, execution continues at the next instruction.

The branch target is stored in immediate[4:0].
Immediate[7:5] and Rs are unused and must be zero.

JNZ tests the register directly, not the Zero flag.

### OUT — Output Register

Copies a register value into the CPU output register.

    OUT R0

Result: Output = R0

The output register connects to the FPGA's
seven-segment displays and VGA monitor.

### HALT — Stop Execution

    HALT

Stops instruction execution until reset.

## 4. Arithmetic and Status Flags

All arithmetic uses 8-bit results.

### Overflow and Underflow

Only the lowest 8 bits of ADD/SUB results are stored.

Examples:

    255 + 1 = 0
    3 - 5 = 254

Arithmetic wraps modulo 256.

### Zero Flag (Z)

The Zero flag updates after ADD, SUB, AND, or OR.

- Z = 1 if the resulting 8-bit value is zero.
- Z = 0 otherwise.

LDI, JNZ, OUT, and HALT do not modify Z.

### HALT Status

A separate HALT status signal indicates that the
processor has stopped execution.

Carry and signed-overflow flags are not implemented
in the initial design.

## 5. Program Counter and ROM

The 5-bit PC addresses 32 instruction words.

| ROM Addresses | Program |
|---|---|
| 0–15 | Arithmetic demonstration |
| 16–31 | Countdown demonstration |

SW1 selects the initial PC value during reset:

- SW1 = 0: PC starts at 0.
- SW1 = 1: PC starts at 16.

The PC normally increments after each instruction.

JNZ can replace the next PC with a branch target.

PC arithmetic is 5-bit, so incrementing 31 wraps to 0.
Both demonstration programs must HALT before
running into the next program's address region.

## 6. Reset Behavior

On active-low reset (KEY0):

- R0–R3 are cleared to 0.
- Output register is cleared to 0.
- Zero flag is cleared to 0.
- HALT status is cleared.
- Last-completed-instruction register is cleared.
- PC loads 0 or 16 according to SW1.
- CPU returns to its initial execution state.

## 7. Example Programs

### Program 1: Addition

    LDI R0, 5
    LDI R1, 3
    ADD R0, R1
    OUT R0
    HALT

Expected output: 8

### Program 2: Countdown

    LDI R0, 9
    LDI R1, 1

    LOOP:
        OUT R0
        SUB R0, R1
        JNZ R0, LOOP

    OUT R0
    HALT

Expected outputs: 9, 8, 7, ..., 1, 0

The assembler/ROM definition will resolve LOOP
to the correct absolute instruction address.

## 8. Execution and Display

The CPU supports two execution modes:

- Manual mode (SW0 = 0): One KEY1 press executes
  one complete instruction.
- Automatic mode (SW0 = 1): Instructions execute
  automatically at a human-observable rate.

The VGA dashboard displays:

- Next Program Counter
- Last completed instruction
- Registers R0–R3
- Output register

The seven-segment displays show the output register.
LEDs indicate the PC, Zero flag, and HALT status.

## 9. Reserved Opcodes

Opcodes 0000 and 1001–1111 are reserved.

An unsupported opcode causes execution to halt.

## 10. Implementation Notes

The CPU core will be implemented separately from
the DE10-Lite hardware interfaces.

Planned hardware modules include:

- alu.v
- register_file.v
- instruction_rom.v
- control_unit.v
- cpu_core.v
- vga_renderer.v
- top.v

Simulation testbenches will verify instruction
execution before FPGA integration.
