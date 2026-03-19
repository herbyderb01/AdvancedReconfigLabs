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
./dlx_asm printConstants_example.dlx printConstants_example_data.mif printConstants_example_code.mif
```

### FPGA Synthesis
Quartus Prime project (`Lab8_DLX_Print.qpf`). Top-level entity is `Lab8_DLX_Print.vhd`. Compile from Quartus GUI. After changing MIF files, do a full recompile (not incremental) to ensure memory initialization updates.

The instruction ROM (`NOP_factorial_ROM`) loads from `./DLXAssembler/printConstants_example_code.mif` and the data RAM (`factorial_ram`) loads from `./DLXAssembler/printConstants_example_data.mif` (paths relative to project root).

### Simulation
ModelSim test benches are in `Tests/`. The main pipeline test bench is `Tests/decode_fetch_execute_memWb/tb_fetch_decode_execute_memWb.vhd`. VCD output can be parsed with `Tests/decode_fetch_execute_memWb/parse_vcd.py`.

### Hardware Testing
- Board: Intel DE10-Lite (MAX 10 FPGA)
- UART: 19200 baud, 8N1 via Arduino header pin IO[1] (TX) → USB-TTL converter → `screen /dev/ttyUSB0 19200`
- Reset: KEY[0] push button (active-low, directly inverted to processor rst)
- SignalTap: use MAX10_CLK1_50 as sample clock, trigger on `fifo_wr` rising edge. Hold KEY[0] during programming, arm SignalTap, then release to capture print instruction execution.

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
        → internal SCFIFO pair (UART_TX_DATA, 32-bit, single-clock 50MHz)
        → FSM: idle → fifo_ready → compute_div → division/stack → wait_for_stack
        → stack (UART/stack.vhd) — 12-entry, combinational empty/full/char_out
        → division IP (LPM_DIVIDE) for PD/PDU integer-to-ASCII
    → character FIFO (dcfifo, 8-bit, dual-clock: 50MHz write / 19.2kHz read)
    → TX_UART (UART/TX_UART.vhd, 19200 baud)
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
- char_translator: FSM with fifo_ready wait state, push_wait, wait_for_pop states
- stack: combinational empty/full/char_out, 12-entry depth, underflow protection
- Top-level: KEY[0] wired as processor reset (active-low inverted)
- PCH verified working on hardware with NOP padding (prints correct 'Y' character via UART at 19200 baud)
- UART chain verified: bypass test confirmed PLL/FIFO/TX_UART all work correctly at 19200 baud
- NOP assembler quirk: `NOP` with no operands assembles as `03FFF800` (garbage register fields but opcode 0x00 is correct). Use `00000000` in MIF for clean NOPs.

### Known issue: forwarding not working for PCH/PD/PDU
PCH/PD/PDU print the wrong value when there's no NOP padding between LW and the print instruction. With two NOPs (so LW completes write-back before PCH reads), output is correct. Without NOPs, the forwarding unit fails to provide the correct value — the print instruction gets stale register data instead of the forwarded LW result. The hazard detection stall and forwarding path for the print opcodes needs further debugging. The issue may be in how `id_ex_rs1_addr` interacts with the forwarding unit for these instructions, or in the timing of the MEM/WB forwarding path.

### What's remaining
- **Fix forwarding for PCH/PD/PDU** — print instructions need correct forwarded data without NOP padding
- Test PD (signed decimal) and PDU (unsigned decimal) printing
- Write the factorial program with string output per lab requirements
- Full pass-off demo: "Welcome to the DLX factorial program!\n6! = 720"
