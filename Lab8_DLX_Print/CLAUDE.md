# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USU ECE 6740 — Custom 5-stage pipelined DLX processor in VHDL targeting the Intel DE10-Lite (MAX 10 FPGA). Includes a custom two-pass C assembler that produces Quartus `.mif` files. The processor supports 49 base instructions (opcodes 0x00–0x30) with hazard detection, forwarding, and stall logic.

## Build Commands

### Assembler
```bash
cd DLXAssembler
gcc -o dlx_asm Assembler.c find_labels.c
./dlx_asm <source.dlx> <data_output.mif> <code_output.mif>
# Example:
./dlx_asm factorial.dlx factorial_data.mif factorial_code.mif
```

### FPGA Synthesis
Quartus Prime project. Open the `.qpf` project file and compile from Quartus GUI. Top-level entity is defined in `top.vhd`.

### Simulation
ModelSim test benches are in `Tests/`. The main pipeline test bench is `Tests/decode_fetch_execute_memWb/tb_fetch_decode_execute_memWb.vhd`. VCD output can be parsed with `Tests/decode_fetch_execute_memWb/parse_vcd.py`.

## Architecture

### Processor Pipeline (DLX_Processor.vhd)
Five stages wired together in `DLX_Processor.vhd`, with `top.vhd` as the FPGA board-level wrapper (adds UART, PLL, LEDs).

| Stage | Key Files |
|-------|-----------|
| Fetch | `FetchModules/fetch.vhd` — PC register, instruction ROM, PC+4 adder |
| Decode | `DecodeModules/decode.vhd`, `DecodeModules/decode_reg/decode_reg.vhd` — register file, sign extension |
| Execute | `ExecuteModules/execute.vhd`, `ExecuteModules/ALU.vhd` — ALU, forwarding MUXes, UART print trigger |
| Memory | `MemoryWriteBackModules/Memory/Memory.vhd` — data RAM |
| Write-back | `MemoryWriteBackModules/Write_back/write_back.vhd` — result MUX, register write control |

### Hazard Handling
- `HazardModules/hazard_detection.vhd` — stall and flush signals for load-use and control hazards
- `HazardModules/forwarding_unit.vhd` — EX/MEM and MEM/WB data forwarding

### Opcode Constants
All opcode constants (`OP_NOP`, `OP_LW`, etc.) are defined in `DecodeModules/decode_reg/decode_reg_pkg.vhd`. This package is used by decode, execute, write-back, hazard detection, and forwarding modules.

### Assembler (DLXAssembler/)
Two-pass C assembler:
- **Pass 1** (`find_labels.c`): scans `.text` segment to build label→address symbol table. The `opcodes[]` array here defines all recognized instruction mnemonics.
- **Pass 2** (`Assembler.c`): parses `.data` segment into data MIF, then translates `.text` instructions into 32-bit hex code MIF. Uses a large if-else chain matching instruction formats (R-type, I-type, J-type, branch).

### Instruction Encoding Formats
- **R-type:** `Op[31:26] | Rd[25:21] | Rs1[20:16] | Rs2[15:11] | Unused[10:0]`
- **I-type:** `Op[31:26] | Rd[25:21] | Rs1[20:16] | Immediate[15:0]`
- **Branch:** `Op[31:26] | Rs1[25:21] | Unused[20:16] | Immediate[15:0]`
- **Jump:** `Op[31:26] | Immediate[25:0]`

### UART Data Path
Execute stage outputs `fifo_wr`, `fifo_data`, `fifo_instr` → SCFIFO → UART TX modules in `UART/` → Arduino header pin on DE10-Lite → serial terminal (PuTTY).

### ROMs
`ROMs/` contains Quartus megafunction-generated altsyncram wrappers for instruction and data memory. These are initialized from `.mif` files produced by the assembler.

## Instruction Reference
Full instruction table with opcodes: `DLXAssembler/DLX_Instructions.md`

## Current Branch (Lab8_DLX_Print)
Adding 3 print instructions: PCH (0x31), PD (0x32), PDU (0x33). Also adding `.const` segment support to the assembler for string constants. See `Lab8_DLX_Print.md` for full requirements.
