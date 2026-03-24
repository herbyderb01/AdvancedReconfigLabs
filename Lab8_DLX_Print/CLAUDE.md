# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USU ECE 6740 — Custom 5-stage pipelined DLX processor in VHDL targeting the Intel DE10-Lite (MAX 10 FPGA). Includes a custom two-pass C assembler that produces Quartus `.mif` files. The processor supports 52 instructions (opcodes 0x00–0x33) with hazard detection, forwarding, and stall logic.

## Build Commands

### Assembler
```bash
cd DLXAssembler
gcc -o dlx_asm Assembler.c find_labels.c
./dlx_asm <source.dlx> <data_output.mif> <code_output.mif>
# Example:
./dlx_asm Factorial_Assemble_Print.dlx printConstants_example_data.mif printConstants_example_code.mif
```

### FPGA Synthesis
Quartus Prime project (`Lab8_DLX_Print.qpf`). Top-level entity is `Lab8_DLX_Print.vhd`. Compile from Quartus GUI. After changing MIF files, do a full recompile (not incremental) to ensure memory initialization updates.

The instruction ROM (`NOP_factorial_ROM`) loads from `./DLXAssembler/printConstants_example_code.mif` and the data RAM (`factorial_ram`) loads from `./DLXAssembler/printConstants_example_data.mif` (paths relative to project root).

### Simulation
ModelSim test benches are in `Tests/`. The main pipeline test bench is `Tests/decode_fetch_execute_memWb/tb_fetch_decode_execute_memWb.vhd`. VCD output can be parsed with `Tests/decode_fetch_execute_memWb/parse_vcd.py`.

### Hardware Testing
- Board: Intel DE10-Lite (MAX 10 FPGA)
- UART: 19200 baud, 8N1 via Arduino header pin IO[1] (TX) → USB-TTL converter → `screen /dev/ttyUSB0 19200`
- Reset: KEY[0] push button (active-low, inverted to processor rst in top-level)
- SignalTap: use MAX10_CLK1_50 as sample clock, trigger on `fifo_wr` rising edge. Hold KEY[0] during programming, arm SignalTap, then release to capture print instruction execution.
- Serial capture: `screen /dev/ttyUSB0 19200`, save output to `serial_ouput.txt` for analysis

## Architecture

### Processor Pipeline (DLX_Processor.vhd)
Five stages wired together in `DLX_Processor.vhd`, with `Lab8_DLX_Print.vhd` as the FPGA board-level wrapper (PLL, UART, character FIFO, char_translator).

| Stage | Key Files |
|-------|-----------|
| Fetch | `FetchModules/fetch.vhd` — PC register, instruction ROM (`NOP_factorial_ROM`), PC+4 adder |
| Decode | `DecodeModules/decode.vhd`, `DecodeModules/decode_reg/decode_reg.vhd` — register file, sign extension |
| Execute | `ExecuteModules/execute.vhd`, `ExecuteModules/ALU.vhd` — ALU, forwarding MUXes, UART print trigger |
| Memory | `MemoryWriteBackModules/Memory/Memory.vhd` — data RAM (`factorial_ram`) |
| Write-back | `MemoryWriteBackModules/Write_back/write_back.vhd` — result MUX, register write control |

### Hazard Handling
- `HazardModules/hazard_detection.vhd` — stall and flush signals for load-use and control hazards
- `HazardModules/forwarding_unit.vhd` — EX/MEM and MEM/WB data forwarding
- `DLX_Processor.vhd` — extracts rs1/rs2/rd addresses for forwarding, computes `ex_mem_wb_en`

**Important:** PCH/PD/PDU use the same register position as BEQZ/BNEZ (rs1 at bits [25:21] instead of [20:16]). All modules that extract register addresses must account for this: `decode.vhd`, `hazard_detection.vhd`, and `DLX_Processor.vhd` (id_ex_rs1_addr). PCH/PD/PDU must also disable write-back in both `write_back.vhd` (wb_en) and `DLX_Processor.vhd` (ex_mem_wb_en).

### Opcode Constants
All opcode constants (`OP_NOP` through `OP_PDU`) are defined in `DecodeModules/decode_reg/decode_reg_pkg.vhd`. This package is used by decode, execute, write-back, hazard detection, forwarding, and char_translator modules.

### Assembler (DLXAssembler/)
Two-pass C assembler (52 instructions):
- **Pass 1** (`find_labels.c`): scans `.text` segment to build label→address symbol table. The `opcodes[]` array here defines all recognized instruction mnemonics (including PCH, PD, PDU). Stops at `.const` or `.data` directives.
- **Pass 2** (`Assembler.c`): parses `.data` and `.const` segments into data MIF, then translates `.text` instructions into 32-bit hex code MIF. Handles segments in any order.
- **`.const` format:** `label_name size "string content"` — each character stored as a 32-bit word at its own address in data memory.
- **Print instruction format:** `PCH rs` / `PD rs` / `PDU rs` — single register at bits [25:21], same as branch encoding.
- **JR/JALR encoding note:** Assembler now puts rs1 at bits [25:21] (shifted left 21), matching how decode reads it for jump register instructions.

### Instruction Encoding Formats
- **R-type:** `Op[31:26] | Rd[25:21] | Rs1[20:16] | Rs2[15:11] | Unused[10:0]`
- **I-type:** `Op[31:26] | Rd[25:21] | Rs1[20:16] | Immediate[15:0]`
- **Branch:** `Op[31:26] | Rs1[25:21] | Unused[20:16] | Immediate[15:0]`
- **Jump:** `Op[31:26] | Immediate[25:0]`
- **Print:** `Op[31:26] | Rs1[25:21] | Unused[20:0]` (PCH/PD/PDU)

### UART Data Path
```
Execute stage (fifo_wr, fifo_data, fifo_instr)
    → char_translator (UART/char_translator.vhd)
        → internal SCFIFO pair (UART_TX_DATA, 32-bit, single-clock 50MHz, show-ahead + output register)
        → FSM: idle → fifo_ready → compute_div → division/stack → wait_for_stack
        → stack (UART/stack.vhd) — 12-entry, combinational empty/full/char_out
        → division IP (LPM_DIVIDE) for PD/PDU integer-to-ASCII
    → character FIFO (dcfifo, 8-bit, dual-clock: 50MHz write / 19.2kHz read)
    → TX_UART (UART/TX_UART.vhd, 19200 baud, LSB first)
    → Arduino header pin IO[1] → USB-TTL → serial terminal
```

### ROMs
`ROMs/` contains Quartus megafunction-generated altsyncram wrappers for instruction and data memory. The active ROM/RAM are in `Tests/decode_fetch_execute_memWb/rom/NOP_factorial_ROM.vhd` and `MemoryWriteBackModules/Memory/RAM/factorial_ram.vhd`, initialized from `.mif` files produced by the assembler.

## Instruction Reference
Full instruction table with opcodes: `DLXAssembler/DLX_Instructions.md`

## Current Branch (Lab8_DLX_Print)
Adding 3 print instructions: PCH (0x31), PD (0x32), PDU (0x33). Also adding `.const` segment support to the assembler for string constants. See `Lab8_DLX_Print.md` for full requirements.

### What's been done
- Assembler: PCH/PD/PDU opcodes added, `.const` segment with quoted string parsing
- Opcode package: OP_PCH, OP_PD, OP_PDU constants added
- Decode: rs1_addr reads [25:21] for PCH/PD/PDU (like BEQZ/BNEZ)
- Decode: rs2_addr bug fixed (AND→OR for SW/JR/JALR condition)
- Execute: fifo_wr/fifo_data/fifo_instr driven combinationally for print opcodes
- Hazard detection: PCH/PD/PDU added to if_id_rs1 special case
- DLX_Processor: id_ex_rs1_addr and ex_mem_wb_en updated for PCH/PD/PDU
- Write-back: wb_en disabled for PCH/PD/PDU
- char_translator: FSM with fifo_ready, push_wait, wait_once_for_push, wait_for_pop, wait_once_for_idle states
- stack: combinational empty/full/char_out, 12-entry depth, underflow protection
- Top-level: KEY[0] wired as processor reset (active-low inverted)

### What's been verified working
- **UART chain**: bypass test confirmed PLL/FIFO/TX_UART all work correctly at 19200 baud
- **PCH**: prints correct characters when there's a natural instruction gap between LW and PCH (e.g., LW→ADDI→PCH pattern works; direct LW→PCH does NOT work without NOP padding)
- **PDU**: hardcoded `ADDI R3, R0, 240` followed by `PDU R3` correctly outputs "240"
- **String printing**: the title loop (LW→ADDI→PCH in a loop) correctly prints "Welcome to the DLX factorial program!" (37 chars)
- **Factorial computation**: with 4 NOPs after each instruction, `4! = 24` computes and prints correctly via PDU
- **Full program output** (with 4x NOPs): `Welcome to the DLX factorial program!\n4! = 24` — title, newline, input number, separator, and factorial result all print correctly

### NOP assembler bug (FIXED)
`NOP` previously assembled as `03FFF800` because the R-type fallthrough branch parsed NULL operands as register 31 (`get_register(NULL)` returns -1, and `-1 & 0x1F = 31`). This was a critical bug — the garbage register fields (R31 in rd/rs1/rs2) caused the forwarding unit to incorrectly forward data from NOP instructions, corrupting registers during the factorial computation. **Fixed** by adding an explicit NOP case in `Assembler.c` before the R-type else branch. NOP now correctly assembles as `00000000`.

### Known issue: requires 4 NOPs between instructions
The factorial program currently needs 4 NOP instructions after every regular instruction to avoid pipeline hazards. This is a brute-force workaround that eliminates all hazards by ensuring every result is written back to the register file before the next instruction reads it. The processor's hazard detection and forwarding should handle this automatically, but something in the pipeline isn't working correctly for certain instruction sequences (particularly around JAL/JR subroutine calls). This needs to be investigated and fixed so the program can run without NOP padding.

### Known issue: PD (signed decimal) produces leading spaces
`PD R1` with R1=4 outputs ~27 space characters before the digit "4". The char_translator's signed decimal path may have a bug in how it handles the division/stack for signed numbers. PDU (unsigned) works correctly. This causes the second line of output to be indented with spaces instead of starting at the left margin.

### Known issue: forwarding not working for direct LW→PCH/PD/PDU
PCH/PD/PDU print the wrong value when directly after LW (no intervening instruction). With one instruction gap (e.g., LW→ADDI→PCH), forwarding works correctly. The workaround is to always have at least one non-dependent instruction between LW and print instructions.

### What's remaining
- **Reduce/eliminate NOP padding** — fix pipeline hazard detection and forwarding so the factorial program runs without 4x NOPs after every instruction
- **Fix PD leading spaces** — signed decimal printing adds ~27 spurious spaces before the number, causing unwanted indentation on new lines
- **Fix direct LW→print forwarding** (nice-to-have, workaround exists with ADDI between LW and print)
- Change n from 4 to 6 for final pass-off demo
- Full pass-off demo: "Welcome to the DLX factorial program!\n6! = 720"
