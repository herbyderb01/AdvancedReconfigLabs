# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USU-DLX: a 5-stage pipelined 32-bit DLX processor implemented in VHDL, targeting the Intel MAX 10 (DE-10 Lite) via Quartus 16.0. The final project goal is to optimize the processor for a timed competition executing two unknown `.dlx` programs.

## Build & Toolchain

**Quartus project:** `FinalProject_DLX_Processor.qpf` — open in Quartus Prime 16.0, device `10M50DAF484C7G`.

**DLX Assembler** (C, in `DLXAssembler/`):
```bash
cd DLXAssembler
gcc -o dlx_asm Assembler.c find_labels.c
./dlx_asm <source>.dlx <data_output>.mif <code_output>.mif
```
The assembler produces `.mif` files that initialize the ROM (code) and RAM (data) in the FPGA design.

**Programming the board:** After Quartus compilation, program via USB-Blaster. Serial I/O uses UART at 19200 baud on Arduino header pins IO0 (RX) / IO1 (TX).

## Architecture

### Pipeline stages (all in `DLX_Processor.vhd`)

1. **Fetch** (`FetchModules/`) — PC register + ROM. Adder increments PC; MUX selects between PC+1 and jump address.
2. **Decode** (`DecodeModules/`) — Register file read, sign extension, instruction field extraction. `decode.vhd` is the main decode logic; `decode_reg/` is the 32×32 register file.
3. **Execute** (`ExecuteModules/`) — ALU operations, branch evaluation (`branch_check.vhd`), print/scan instruction handling. Forwarding MUX inputs are resolved here.
4. **Memory** (`MemoryWriteBackModules/Memory/`) — Data RAM (currently `factorial_ram.vhd` MIF-initialized). LW/SW access happens here.
5. **Write-back** (`MemoryWriteBackModules/Write_back/`) — MUX selects ALU result, RAM output, or PC+1 (for JAL/JALR) to write back to register file.

### Hazard handling

- **Forwarding unit** (`HazardModules/forwarding_unit.vhd`) — EX-EX and MEM-EX forwarding with `fwd_a_sel`/`fwd_b_sel` mux controls.
- **Hazard detection** (`HazardModules/hazard_detection.vhd`) — Load-use stall detection.
- **Branch flush** — 2-cycle branch penalty: `flush_raw` from execute + 1-cycle delayed `flush_r1`.
- **Scan stall** — Registered latch in `DLX_Processor.vhd` freezes pipeline when GD/GDU instruction is fetched until `scan_ready` goes high.
- Stall is gated by flush and also stalls on `fifo_full`.

### UART / I/O subsystem (top-level `FinalProject_DLX_Processor.vhd`)

- **TX path:** Execute stage writes 32-bit data + instruction to `char_translator` (`UART/char_translator.vhd`) which converts to ASCII bytes → FIFO → `TX_UART`.
- **RX path:** `RX_UART` → dcfifo (clock domain crossing 153.6 kHz → 50 MHz) → `ascii_to_int` FSM → 32-bit `scan_data`/`scan_ready` to processor.
- PLL generates `clk_rx_8x` (153.6 kHz) and `clk_tx_1x` (19.2 kHz) from 50 MHz input clock.

### Opcode constants

All opcodes are defined in `DecodeModules/decode_reg/decode_reg_pkg.vhd` and used throughout. Custom I/O instructions beyond standard DLX:
- `PCH` (0x31) — print character
- `PD` (0x32) — print decimal (signed)
- `PDU` (0x33) — print decimal (unsigned)
- `GD` (0x34) — get decimal (signed scan)
- `GDU` (0x35) — get decimal (unsigned scan)
- Timer instructions (TR, TGO, TSP) still need to be implemented for final project.

### Instruction encoding

- **R-type:** `[31:26] opcode | [25:21] rd | [20:16] rs1 | [15:11] rs2 | [10:0] unused`
- **I-type:** `[31:26] opcode | [25:21] rd | [20:16] rs1 | [15:0] immediate`
- **J-type:** `[31:26] opcode | [25:0] target`
- Branch/print use rs1 at `[25:21]`; SW/JR/JALR use rs2 at `[25:21]`.

### Key register-address extraction (watch for bugs)

In `DLX_Processor.vhd`, source register addresses for forwarding are extracted with special cases:
- `rs1_addr` uses `[25:21]` for BEQZ/BNEZ/PCH/PD/PDU, else `[20:16]`
- `rs2_addr` uses `[25:21]` for SW/JR/JALR, else `[15:11]`

The same logic must be mirrored in `decode.vhd` — mismatches between these two cause forwarding bugs.

## Assembly language

`.dlx` source files use `.data` and `.text` segments. The `.data` segment defines variables with `<name> <size> <values...>`. Labels in `.text` are resolved by the two-pass assembler. See `DLXAssembler/DLX_Instructions.md` for the full ISA table.
