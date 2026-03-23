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
- **PD R1**: prints the input number (4) but with ~27 leading spaces — PD (signed decimal) may have a bug producing extra space characters

### Known issue: factorial computation produces wrong result
The factorial program (`Factorial_Assemble_Print.dlx`) for n=4 produces R3=832700416 (0x31A00000) instead of R3=24. This was confirmed by adding `PDU R3` immediately after `SW f(R0), R3` at the `done` label. The value 0x31A00000 looks like an instruction encoding, suggesting a register is getting corrupted by stale pipeline data during the factorial's multiply loop (JAL/JR calls to f_multiply).

**Next debugging step:** Test with n=3 (3!=6, only one multiply call) to isolate whether the bug is in the first multiply iteration or subsequent ones. If n=3 gives R3=6, the issue is in how the pipeline handles the second JAL/JR call or the outer loop's register state across iterations.

**Possible causes to investigate:**
- Pipeline hazards in the f_multiply function (ADD→SUBI→BNEZ→JR sequence)
- JAL/JR interaction with the 2-cycle branch penalty — flushed instructions may corrupt register state
- The SUBI R4,R4,2 / ADDI R4,R4,1 pattern in f_multiply may interact badly with branch penalties
- Forwarding around JAL (R31 write-back) could interfere with other register forwarding

### Known issue: forwarding not working for direct LW→PCH/PD/PDU
PCH/PD/PDU print the wrong value when directly after LW (no intervening instruction). With one instruction gap (e.g., LW→ADDI→PCH), forwarding works correctly. The workaround is to always have at least one non-dependent instruction between LW and print instructions.

### Known issue: PD (signed decimal) produces leading spaces
`PD R1` with R1=4 outputs ~27 space characters before the digit "4". The char_translator's signed decimal path may have a bug. PDU (unsigned) works correctly.

### NOP assembler quirk
`NOP` with no operands assembles as `03FFF800` (garbage register fields from parsing NULL operands, but opcode 0x00 is correct). For clean NOPs in hand-edited MIF files, use `00000000`.

### What's remaining
- **Fix factorial pipeline bug** — R3 gets corrupted during multiply loop
- **Fix PD leading spaces** — signed decimal printing adds spurious spaces
- **Fix direct LW→print forwarding** (nice-to-have, workaround exists)
- Complete the factorial program with correct output
- Full pass-off demo: "Welcome to the DLX factorial program!\n6! = 720"
