# Advanced Reconfigurable Computing DLX Execute Requirements

## Introduction

Your task is to implement and verify the EXECUTE stage of the DLX architecture in conjunction with your
previously-implemented FETCH and DECODE stages.
Figure 1: DLX 5-stage pipeline architecture with Execute stage highlighted

## Requirements

1. The lab will be done in modular, hierarchical VHDL. Your top module should be named
something like “DLX”. Under this top level you should have a FETCH module, a DECODE module,
and an EXECUTE module.

2. Implement the ALU, multiplexers, “Zero?”, appropriate registers, and any needed control logic
as shown in Figure 1, with the modifications discussed in class.

3. Include the previously-created VHDL package, modified if necessary, for defining constants and
such that will need to be shared across the architecture.

4. Design appropriate Questa test-benches to exercise your FETCH, DECODE, and EXECUTE stages
working together. Verify that your architecture successfully handles the four examples from the
first lab (example1, example2, example3, and factorial). Exercise the four inputs to the system
in a variety of ways.

## Pass-off

10 pts – Demonstrate to the instructor a ModelSim simulation of your factorial example. Simulate
branches, jumps and memory accesses in the appropriate spots in the code. Demonstrate that the
FETCH, DECODE, and EXECUTE stages work correctly in the pipeline.


We're currently in the process of writing each stage of a DLX Processor in VHDL. I've written what I think to be the fetch and decode stage and tested and they work according to the testbenches I've written. I've copied all that work into this folder `Lab5_DLX_Execute` and now I need to write the execute stage. Can I get your help with the this stage? 
