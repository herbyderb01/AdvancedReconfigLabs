# Advanced Reconfigurable Computing DLX Memory & Write-Back Requirements

## Introduction

Your task is to implement and verify the MEMORY and WRITE_BACK stages of the DLX architecture in
conjunction with your previously-implemented FETCH, DECODE and EXECUTE stages.
Figure 1: DLX 5-stage pipeline architecture with MEMORY and WRITE_BACK stages highlighted

## Requirements

1. The lab will be done in modular, hierarchical VHDL. Your top module should be named
something like “DLX”. Under this top level you should have a FETCH module, a DECODE module,
an EXECUTE module, a MEMORY module, and a WRITE-BACK module.
2. Implement the Data Memory and Write-Back Multiplexer, appropriate registers, and any
needed control logic as shown in Figure 1 and discussed in class.
3. Include the previously-created VHDL package, modified if necessary, for defining constants and
such that will need to be shared across the architecture.
4. The only inputs to the system should be a clock and a reset. There are no outputs.
5. Design appropriate Questa or ModelSim test-benches to exercise your “complete” DLX
architecture. Verify that your architecture successfully handles modified versions of the four
examples from the first lab (example1, example2, example3, and factorial). Modify these DLX
files to avoid data hazards and control hazards, as discussed in class.

## Pass-off

10 pts – Demonstrate to the instructor a Questa or ModelSim simulation of your modified factorial
example. Show that an input value read from data memory becomes the correct output value written
back to data memory. For example, a 6 should generate a 720.
