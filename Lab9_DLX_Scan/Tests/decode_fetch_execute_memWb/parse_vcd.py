#!/usr/bin/env python3
"""Parse pipeline_debug.vcd and reconstruct multi-bit signals cycle by cycle."""

import re, sys

VCD_FILE = "pipeline_debug.vcd"

# ── 1. Parse header: build id → (signal_name, bit_index) map ──
scope_stack = []
id_to_signal = {}   # id_char → (full_signal_name, bit_index_or_None)

with open(VCD_FILE) as f:
    in_defs = True
    lines = f.readlines()

idx = 0
while idx < len(lines):
    line = lines[idx].strip()
    idx += 1
    if line.startswith("$scope"):
        parts = line.split()
        scope_stack.append(parts[2])
    elif line.startswith("$upscope"):
        scope_stack.pop()
    elif line.startswith("$var"):
        # $var wire 1 ! clk $end
        parts = line.split()
        # parts: $var, type, width, id, name, [bit_sel], $end
        vid = parts[3]
        name = parts[4]
        bit_sel = None
        if len(parts) > 6 and parts[5] != "$end":
            m = re.match(r'\[(\d+)\]', parts[5])
            if m:
                bit_sel = int(m.group(1))
        full_name = ".".join(scope_stack) + "." + name
        id_to_signal[vid] = (full_name, bit_sel)
    elif line.startswith("$enddefinitions"):
        in_defs = False
        break

# ── 2. Group single-bit VCD vars into multi-bit bus signals ──
# Group by signal name
from collections import defaultdict
bus_ids = defaultdict(list)  # full_name → [(bit_index, id_char)]
scalar_ids = {}              # full_name → id_char

for vid, (name, bit) in id_to_signal.items():
    if bit is not None:
        bus_ids[name].append((bit, vid))
    else:
        scalar_ids[name] = vid

# Sort each bus by bit index descending (MSB first)
for name in bus_ids:
    bus_ids[name].sort(key=lambda x: -x[0])

# ── 3. Track current state of every VCD variable ──
current_val = {}  # id_char → '0' or '1' or 'x' etc.

def reconstruct_bus(name):
    """Reconstruct a bus value from individual bits."""
    bits = bus_ids[name]
    val = ""
    for bit_idx, vid in bits:
        v = current_val.get(vid, 'x')
        val += v
    return val

def bus_to_hex(binstr):
    """Convert a binary string to hex."""
    if 'x' in binstr or 'X' in binstr or 'u' in binstr or 'U' in binstr:
        return "X"*((len(binstr)+3)//4)
    try:
        return format(int(binstr, 2), '0' + str((len(binstr)+3)//4) + 'X')
    except:
        return binstr

# Signals we care about (short names for display)
SIGNALS_OF_INTEREST = {
    "tb_hazard_factorial.uut.fetch_inst.addr":    ("addr",    10),
    "tb_hazard_factorial.uut.internal_instr":      ("IF_instr", 32),
    "tb_hazard_factorial.uut.internal_pc_inc":     ("IF_pc",   10),
    "tb_hazard_factorial.uut.dec_instruction":     ("ID_instr", 32),
    "tb_hazard_factorial.uut.dec_rs1_data":        ("ID_rs1",  32),
    "tb_hazard_factorial.uut.dec_rs2_data":        ("ID_rs2",  32),
    "tb_hazard_factorial.uut.dec_imm32":           ("ID_imm",  32),
    "tb_hazard_factorial.uut.exec_instr":          ("EX_instr", 32),
    "tb_hazard_factorial.uut.exec_alu_result":     ("EX_alu",  32),
    "tb_hazard_factorial.uut.exec_branch_en":      ("EX_br",    1),
    "tb_hazard_factorial.uut.jump_addr":           ("jmp_addr",10),
    "tb_hazard_factorial.uut.memory_inst.trunc_addr": ("M_addr", 10),
    "tb_hazard_factorial.uut.memory_inst.wren":    ("M_wren",   1),
    "tb_hazard_factorial.uut.mem_reg_ALU":         ("M_ALU",   32),
    "tb_hazard_factorial.uut.mem_RAM_output":      ("M_RAM",   32),
    "tb_hazard_factorial.uut.wb_addr":             ("WB_addr",  5),
    "tb_hazard_factorial.uut.wb_data":             ("WB_data", 32),
    "tb_hazard_factorial.uut.wb_en":               ("WB_en",    1),
    "tb_hazard_factorial.uut.stall":               ("stall",    1),
    "tb_hazard_factorial.uut.flush":               ("flush",    1),
    "tb_hazard_factorial.uut.fwd_a_sel":           ("fwdA",     2),
    "tb_hazard_factorial.uut.fwd_b_sel":           ("fwdB",     2),
}

# Opcode decoding
OPCODES = {
    0x00: "NOP", 0x01: "LW", 0x02: "SW", 0x03: "ADD", 0x04: "ADDI",
    0x05: "ADDUI", 0x06: "AND", 0x07: "ANDI", 0x08: "SUBI",
    0x09: "OR", 0x0A: "ORI", 0x0B: "XOR", 0x0C: "XORI",
    0x0D: "SLL", 0x0E: "SLLI", 0x0F: "SRL", 0x10: "SRLI",
    0x11: "SRA", 0x12: "SRAI", 0x13: "SLT", 0x14: "SLTI",
    0x15: "SGT",  0x16: "SGTI", 0x17: "SLE", 0x18: "SLEI",
    0x19: "SGE", 0x1A: "SGEI", 0x1B: "SEQ", 0x1C: "SEQI",
    0x1D: "SNE", 0x1E: "SNEI", 0x1F: "SUB",
    0x20: "SLTU", 0x21: "SLTUI", 0x22: "SGTU", 0x23: "SGTUI",
    0x24: "SLEU", 0x25: "SLEUI", 0x26: "SGEU", 0x27: "SGEUI",
    0x28: "SUBU", 0x29: "ADDU",
    0x2A: "BEQZ", 0x2B: "BNEZ",0x2C: "J", 0x2D: "JR",
    0x2E: "JAL", 0x2F: "JALR",
}

def decode_instr_str(hexval):
    """Decode a 32-bit instruction hex string into assembly."""
    try:
        val = int(hexval, 16)
    except:
        return hexval
    opcode = (val >> 26) & 0x3F
    mnemonic = OPCODES.get(opcode, f"?{opcode:02X}")
    rd = (val >> 21) & 0x1F
    rs1 = (val >> 16) & 0x1F
    rs2 = (val >> 11) & 0x1F
    imm16 = val & 0xFFFF
    if opcode in (0x03, 0x1F, 0x29, 0x28, 0x06, 0x09, 0x0B, 0x0D, 0x0F, 0x11,
                  0x13, 0x15, 0x17, 0x19, 0x1B, 0x1D, 0x20, 0x22, 0x24, 0x26):
        return f"{mnemonic} R{rd},R{rs1},R{rs2}"
    elif opcode in (0x2A, 0x2B):  # BEQZ/BNEZ
        return f"{mnemonic} R{rd},{imm16:#06x}"
    elif opcode in (0x2C,):  # J
        return f"{mnemonic} {(val & 0x3FFFFFF):#010x}"
    elif opcode in (0x2D, 0x2F):  # JR/JALR
        return f"{mnemonic} R{rd}"
    elif opcode == 0x01:  # LW
        return f"{mnemonic} R{rd},{imm16}(R{rs1})"
    elif opcode == 0x02:  # SW
        return f"{mnemonic} {imm16}(R{rs1}),R{rd}"
    elif opcode == 0x2E:  # JAL
        return f"{mnemonic} {(val & 0x3FFFFFF):#010x}"
    else:
        return f"{mnemonic} R{rd},R{rs1},{imm16:#06x}"
    return mnemonic

# ── 4. Parse value changes and print per-clock-edge ──

time = 0
clk_id = None
rst_id = None

# Find clk and rst IDs
for vid, (name, bit) in id_to_signal.items():
    if name.endswith(".clk"):
        clk_id = vid
    if name.endswith(".tb_rst"):
        rst_id = vid

prev_clk = '0'
cycle = 0
snapshots = []

def take_snapshot():
    snap = {"cycle": cycle, "time": time}
    for full_name, (short, width) in SIGNALS_OF_INTEREST.items():
        if width == 1:
            if full_name in scalar_ids:
                snap[short] = current_val.get(scalar_ids[full_name], 'x')
            elif full_name in bus_ids:
                snap[short] = reconstruct_bus(full_name)
        else:
            if full_name in bus_ids:
                snap[short] = bus_to_hex(reconstruct_bus(full_name))
            else:
                snap[short] = "?"
    snapshots.append(snap)

# Continue parsing from where we left off
while idx < len(lines):
    line = lines[idx].strip()
    idx += 1
    
    if not line:
        continue
    
    if line.startswith('#'):
        new_time = int(line[1:])
        time = new_time
        continue
    
    if line.startswith('$'):
        # Skip $dumpvars, $end, etc.
        if line == '$dumpvars':
            continue
        if line == '$end':
            continue
        continue
    
    # Value change: either "0X" / "1X" for single bit, or "bXXXX ID" for multi
    if line[0] in ('0', '1', 'x', 'X', 'z', 'Z'):
        val = line[0]
        vid = line[1:]
        old_clk = current_val.get(clk_id, '0')
        current_val[vid] = val
        # Check for rising clock edge
        if vid == clk_id and old_clk == '0' and val == '1':
            cycle += 1
            take_snapshot()
    elif line[0] == 'b':
        parts = line.split()
        bval = parts[0][1:]  # binary value without 'b'
        vid = parts[1]
        # Handle multi-bit as individual — VCD uses individual bits here
        current_val[vid] = bval

# Print summary for first 50 cycles focusing on pipeline flow
print(f"{'Cyc':>3} {'T':>6} {'St':>2} {'Fl':>2} {'fA':>2} {'fB':>2} | "
      f"{'addr':>4} {'IF_instr':>10} | {'ID_instr':>10} {'ID_rs1':>10} {'ID_rs2':>10} {'ID_imm':>10} | "
      f"{'EX_instr':>10} {'EX_alu':>10} {'Br':>2} | "
      f"{'WB_addr':>3} {'WB_data':>10} {'WE':>2}")
print("-" * 180)

for snap in snapshots[:80]:
    c = snap['cycle']
    t = snap['time']
    st = snap.get('stall', '?')
    fl = snap.get('flush', '?')
    fa = snap.get('fwdA', '??')
    fb = snap.get('fwdB', '??')
    
    addr = snap.get('addr', '???')
    if_instr = snap.get('IF_instr', '????????')
    id_instr = snap.get('ID_instr', '????????')
    id_rs1 = snap.get('ID_rs1', '????????')
    id_rs2 = snap.get('ID_rs2', '????????')
    id_imm = snap.get('ID_imm', '????????')
    ex_instr = snap.get('EX_instr', '????????')
    ex_alu = snap.get('EX_alu', '????????')
    br = snap.get('EX_br', '?')
    wb_addr_v = snap.get('WB_addr', '??')
    wb_data_v = snap.get('WB_data', '????????')
    wb_en_v = snap.get('WB_en', '?')
    
    # Decode instruction mnemonics
    if_asm = decode_instr_str(if_instr) if if_instr != '????????' else '?'
    id_asm = decode_instr_str(id_instr) if id_instr != '????????' else '?'
    ex_asm = decode_instr_str(ex_instr) if ex_instr != '????????' else '?'
    
    try:
        wb_a = int(wb_addr_v, 16)
    except:
        wb_a = wb_addr_v
    
    print(f"{c:>3} {t:>6} {st:>2} {fl:>2} {fa:>2} {fb:>2} | "
          f"{addr:>4} {if_instr:>10} | {id_instr:>10} {id_rs1:>10} {id_rs2:>10} {id_imm:>10} | "
          f"{ex_instr:>10} {ex_alu:>10} {br:>2} | "
          f" R{wb_a!s:<2} {wb_data_v:>10} {wb_en_v:>2}")
    print(f"    {'':>6} {'':>2} {'':>2} {'':>2} {'':>2} | "
          f"{'':>4} {if_asm:>20} | {id_asm:>20} {'':>10} {'':>10} {'':>10} | "
          f"{ex_asm:>20} {'':>10} {'':>2} |")
    
print(f"\nTotal clock cycles captured: {len(snapshots)}")
