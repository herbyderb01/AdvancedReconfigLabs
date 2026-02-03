# Advanced Reconfigurable Computing DLX Decode Requirements

## Introduction

Your task is to implement and verify the DECODE stage of the DLX architecture in conjunction with your
previously-implemented FETCH stage.

Stages: Fetch, Decode, Execute, Memory, Writeback
Figure 1: DLX 5-stage pipeline architecture with DECODE stage highlighted

## Requirements

1. The lab will be done in modular, hierarchical VHDL. Your top module should be named something like “DLX”. Under this top level you should have a FETCH module and a DECODE module.

2. Implement the Register File, Sign Extender, appropriate registers, and any needed control logic as shown in Figure 1, with the modifications discussed in class.

3. Create a VHDL package for defining constants and such that will need to be shared across the architecture.

4. Design appropriate ModelSim test-benches to exercise your FETCH and DECODE stages. Verify that your architecture successfully handles the four examples from the first lab (example1, example2, example3, and factorial). Exercise the four inputs to the system in a variety of ways.

## Pass-off

10 pts – Demonstrate to the instructor a simulation of your factorial example. Simulate branches and
jumps in the appropriate spots in the code. Demonstrate that the FETCH and DECODE stages work
correctly as stages in the pipeline. Also, show the instructor your VHDL package.
