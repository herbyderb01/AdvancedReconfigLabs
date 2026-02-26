# Advanced Reconfigurable Computing DLX Hazard Requirements

## Introduction

Your task is to implement and verify DLX data and control hazard mitigation techniques discussed in
class.

## Requirements

1. The lab will be done in modular, hierarchical VHDL.
2. Implement data forwarding to minimize the effect of data hazards.
3. Handle data hazards that forwarding cannot resolve by stalling the pipeline.
4. Select a method for handling control hazards and implement it.
5. The only inputs to the system should be a clock and a reset. There are no outputs.
6. Design appropriate Questa test-benches to exercise your “complete” DLX architecture. Verify
that your architecture successfully handles the original (not modified with NOPs) versions of the
four examples from the first lab (example1, example2, example3, and factorial). All hazards
should be handled by the architecture.

## Pass-off

10 pts – Demonstrate to the instructor a Questa simulation of your factorial example with no NOP
instructions. Show that an input value read from data memory becomes the correct output value
written back to data memory. For example, a 6 should generate a 720.