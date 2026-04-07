# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

USU-DLX: a 5-stage pipelined 32-bit DLX processor implemented in VHDL, targeting the Intel MAX 10 (DE-10 Lite) via Quartus Prime, device `10M50DAF484C7G`. The final project goal is to optimize the processor for a timed competition executing two unknown `.dlx` programs on 2026-04-24.

## Build & Toolchain

**Quartus project:** `FinalProject_DLX_Processor.qpf` — all design files are included via `dlx_project_files.qip`.

**DLX Assembler** (C, in `DLXAssembler/`):
```bash
cd DLXAssembler
gcc -o dlx_asm Assembler.c find_labels.c
./dlx_asm <source>.dlx <data_output>.mif <code_output>.mif
```
The assembler produces `.mif` files that initialize the ROM (code) and RAM (data) in the FPGA design.

**Changing the program:** Edit the `init_file` path in the ROM VHDL (`ROMs/DLX_ROM.vhd`) and RAM VHDL (`MemoryWriteBackModules/Memory/RAM/factorial_ram.vhd`) to point to the new `.mif` files. Paths are relative to the Quartus project directory.

**Programming the board:** After Quartus compilation, program via USB-Blaster. Serial I/O uses UART at 19200 baud on Arduino header pins IO0 (RX) / IO1 (TX).

**Quartus settings notes:**
- Device must be `10M50DAF484C7G` (not the 8K variant)
- Configuration mode: `Single Uncompressed Image with Memory Initialization` (required for .mif support)
- Junction temperature: 0–85 C (commercial grade for C7G part)

## Architecture

### Pipeline stages (all wired in `DLX_Processor.vhd`)

1. **Fetch** (`FetchModules/`) — PC register + ROM. Adder increments PC; MUX selects between PC+1 and jump address.
2. **Decode** (`DecodeModules/`) — Register file read (synchronous), sign extension, instruction field extraction. `decode.vhd` is the main decode logic; `decode_reg/decode_reg.vhd` is the 32×32 register file.
3. **Execute** (`ExecuteModules/`) — ALU operations, branch evaluation (`branch_check.vhd`), print/scan instruction handling. Forwarding MUX inputs are resolved here.
4. **Memory** (`MemoryWriteBackModules/Memory/`) — Data RAM (`factorial_ram.vhd`, MIF-initialized). LW/SW access happens here.
5. **Write-back** (`MemoryWriteBackModules/Write_back/`) — Combinational MUX selects ALU result, RAM output, or PC+1 (for JAL/JALR) to write back to register file.

### Hazard handling

- **Forwarding unit** (`HazardModules/forwarding_unit.vhd`) — EX/MEM and MEM/WB forwarding with `fwd_a_sel`/`fwd_b_sel` mux controls. Verified correct.
- **Hazard detection** (`HazardModules/hazard_detection.vhd`) — Load-use stall detection for LW. Verified correct.
- **Branch flush** — 2-cycle branch penalty: `flush_raw` from execute + 1-cycle delayed `flush_r1`.
- **Scan stall** — Registered latch in `DLX_Processor.vhd` freezes pipeline when GD/GDU instruction is fetched until `scan_ready` goes high. Has a known issue (see below).
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
- **rd is at [25:21] for ALL instruction types** (confirmed in Assembler.c). This is different from standard MIPS where R-type rd is at [15:11].

### Key register-address extraction (watch for bugs)

In `DLX_Processor.vhd`, source register addresses for forwarding are extracted with special cases:
- `rs1_addr` uses `[25:21]` for BEQZ/BNEZ/PCH/PD/PDU, else `[20:16]`
- `rs2_addr` uses `[25:21]` for SW/JR/JALR, else `[15:11]`

The same logic must be mirrored in `decode.vhd` — mismatches between these two cause forwarding bugs.

## Assembly language

`.dlx` source files use `.data` and `.text` segments. The `.data` segment defines variables with `<name> <size> <values...>`. Labels in `.text` are resolved by the two-pass assembler. See `DLXAssembler/DLX_Instructions.md` for the full ISA table.

## Bug fixes applied

### Register file bypass bug (FIXED)

**File:** `DecodeModules/decode_reg/decode_reg.vhd`

The register file's synchronous read had a write-then-read bypass that activated when `read_addr = write_addr`, **regardless of `reg_write_en`**. When a non-writing instruction (SW, BEQZ, BNEZ, J, JR, PCH, PD, PDU) was in write-back, its bits [25:21] could match a source register being read, causing the register file to output garbage instead of the correct value.

**Fix applied:** Added `reg_write_en = '1'` check to both read-port bypass conditions. This was the root cause of needing 4 NOPs after every instruction or manual instruction reordering.

**WARNING:** There is a duplicate file `DecodeModules/decode_reg.vhd` (NOT in the subdirectory) that still has the old buggy code AND an additional bug (`reg_write_addr2 /= reg_write_data` compares address to data). Do NOT include it in the Quartus project — only use `DecodeModules/decode_reg/decode_reg.vhd`.

### Stall/flush interaction (FIXED)

**File:** `DLX_Processor.vhd`, line 151

When `flush='1'` AND `fifo_full='1'` simultaneously, stall would freeze the PC instead of redirecting to the branch target. Fixed by gating `fifo_full` with `not flush`.

## Known remaining issues

### 1. RAM .mif initialization not loading (UNTESTED FIX PENDING)

**Symptom:** Tests T3 and T4 in `hazard_test.dlx` get wrong values from LW (T3 prints nothing instead of 7; T4 prints 42 instead of 20). The data RAM appears uninitialized or loaded from a stale .mif.

**Root cause:** Likely the `init_file` path in `factorial_ram.vhd` is not resolving correctly during Quartus compilation. Check the compilation log for warnings about "Can't find MIF file".

**Possible fix:** Use an absolute path in `factorial_ram.vhd` for `init_file`, or copy the data .mif to the project root directory.

### 2. Scan stall skips instruction after GD/GDU (UNTESTED FIX PENDING)

**Symptom:** In `hazard_test.dlx`, PDU/PD placed immediately after GDU/GD does not execute. T12 prints "N:=10" instead of "N:5=10"; T13 prints "S:P" instead of "S:3P". The computation results are correct, only the echo is missing.

**Root cause:** The scan stall (`scan_stalling`) is registered, so it takes effect one cycle after GDU is detected in `internal_instr`. By then, the PC has already advanced two positions past GDU (to GDU+2). The instruction at GDU+1 gets skipped — it appears in `internal_instr` for one cycle but decode is in hold mode and never captures it.

**Attempted fix:** A combinational `scan_stall_imm` was tried to fire immediately when GDU is detected, but it caused regressions (PCH output stopped working entirely). This was reverted.

**Workaround:** Place a NOP or unrelated instruction immediately after GD/GDU — the instruction at GDU+1 will be skipped, so don't put anything important there.

**Proper fix needed:** The scan stall mechanism needs redesign. Options:
- Detect GD/GDU at the address/ROM-input stage instead of the ROM-output stage (earlier detection)
- Adjust the PC back by 1 when scan_stall first activates
- Use the combinational approach but investigate why it caused PCH regressions

### 3. Forwarding verified correct

The following were verified correct and do NOT need changes:
- Forwarding unit (EX/MEM and MEM/WB paths with priority)
- Hazard detection (load-use stall for LW)
- Execute forwarding MUXes
- Write-back wb_en and wb_addr extraction
- Register address extraction in DLX_Processor.vhd matches decode.vhd
- Branch handling (2-cycle flush)

## Test program

`DLXAssembler/hazard_test.dlx` — comprehensive pipeline hazard test with 13 tests:
- T1-T4: Forwarding and load-use hazards
- T5: Branch after ALU with forwarding
- T6-T7: Register file bypass bug regression tests
- T8: JAL/JR function call chain
- T9: Simultaneous rs1+rs2 forwarding
- T10: Register file direct read (3+ gap)
- T11: Dependency chain A→B→C
- T12-T13: GDU/GD scan tests (interactive, require serial input)

**Last test results (before scan stall regression):** T1, T2, T5, T6, T7, T8, T9, T10, T11 all PASS. T3, T4 fail (RAM .mif issue). T12, T13 partially work (scan stall skips echo).

## Still TODO

- Fix RAM .mif path so LW tests work
- Fix scan stall to not skip instruction after GD/GDU
- Implement stopwatch timer (TR, TGO, TSP instructions + seven-segment display)
- Check signed printing and scanning
- Test against all of Dr. Phillips' DLX programs
