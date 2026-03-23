# ============================================================
# Lab 7 — DLX Hazard Mitigation — Questa Compile & Simulate
# ============================================================
# Usage:  In Questa, cd to the Tests/decode_fetch_execute_memWb/
#         directory, then: do compile_hazard.do
#
# This script compiles all source files from their original
# module directories (with hazard modifications) and runs
# the factorial test bench.
# ============================================================

# Quit any running simulation
quit -sim

# Set the base directory (Lab7_DLX_Hazards root)
set BASE "../../"

# ============================================================
# Ensure MIF files are in the simulation directory
# (altsyncram resolves init_file relative to vsim cwd)
# ============================================================
if {![file exists factorial_code.mif]} {
    file copy rom/factorial_code.mif factorial_code.mif
}

# Create fresh work library
if {[file exists work]} {
    vdel -all -lib work
}
vlib work

# ============================================================
# 1. PACKAGES (must be compiled first)
# ============================================================
vcom -work work ${BASE}FetchModules/MUX/MUX_pkg.vhd
vcom -work work ${BASE}FetchModules/Register/register_pkg.vhd
vcom -work work ${BASE}FetchModules/Register/register_async_pkg.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/half_adder_pkg.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/full_adder_pkg.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/ripple_adder_pkg.vhd
vcom -work work ${BASE}DecodeModules/decode_reg/decode_reg_pkg.vhd
vcom -work work ${BASE}DecodeModules/sign_extend/sign_extend_pkg.vhd
vcom -work work rom/NOP_factorial_ROM_pkg.vhd
vcom -work work ${BASE}FetchModules/fetch_pkg.vhd

# ============================================================
# 2. BASIC COMPONENTS (register, MUX, adder)
# ============================================================
vcom -work work ${BASE}FetchModules/Register/register.vhd
vcom -work work ${BASE}FetchModules/Register/register_async.vhd
vcom -work work ${BASE}FetchModules/MUX/MUX.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/half_adder.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/full_adder.vhd
vcom -work work ${BASE}FetchModules/ripple_adder/ripple_adder.vhd

# ============================================================
# 3. IP CORES (ROM and RAM — Altera MF)
# ============================================================
vcom -work work rom/NOP_factorial_ROM.vhd
vcom -work work MemoryWriteBackModules/Memory/RAM/factorial_ram.vhd

# ============================================================
# 4. FETCH STAGE (with stall support)
# ============================================================
vcom -work work ${BASE}FetchModules/fetch.vhd

# ============================================================
# 5. DECODE STAGE (with stall + flush)
# ============================================================
vcom -work work ${BASE}DecodeModules/decode_reg/decode_reg.vhd
vcom -work work ${BASE}DecodeModules/sign_extend/sign_extend.vhd
vcom -work work ${BASE}DecodeModules/decode.vhd

# ============================================================
# 6. EXECUTE STAGE (with forwarding + flush)
# ============================================================
vcom -work work ${BASE}ExecuteModules/ALU.vhd
vcom -work work ${BASE}ExecuteModules/branch_check.vhd
vcom -work work ${BASE}ExecuteModules/execute.vhd

# ============================================================
# 7. MEMORY STAGE
# ============================================================
vcom -work work ${BASE}MemoryWriteBackModules/Memory/Memory.vhd

# ============================================================
# 8. WRITE-BACK STAGE
# ============================================================
vcom -work work ${BASE}MemoryWriteBackModules/Write_back/write_back.vhd

# ============================================================
# 9. HAZARD MODULES (new for Lab 7)
# ============================================================
vcom -work work ${BASE}HazardModules/forwarding_unit.vhd
vcom -work work ${BASE}HazardModules/hazard_detection.vhd

# ============================================================
# UART MODULEs
# ============================================================
vcom -work work ${BASE}UART/division.vhd
vcom -work work ${BASE}UART/FIFO.vhd
vcom -work work ${BASE}UART/PLL_UART.vhd
vcom -work work ${BASE}UART/stack.vhd
vcom -work work ${BASE}UART/TX_UART.vhd
vcom -work work ${BASE}UART/UART_TX_DATA.vhd
vcom -work work ${BASE}UART/char_translator.vhd

# ============================================================
# 10. TOP-LEVEL PROCESSOR + TEST BENCH
# ============================================================
vcom -work work ${BASE}DLX_Processor.vhd
vcom -work work ${BASE}LAB8_DLX_Print.vhd
vcom -work work tb_hazard_factorial.vhd

# ============================================================
# SIMULATE
# ============================================================
vsim -t ns work.tb_hazard_factorial

do wave.do

# Run the simulation
# run 2 us

# Zoom to fit
wave zoom full
