# Lab3_DLX_Fetch

## Introduction 

Your task is to implement and verify the FETCH stage of the DLX architecture. 
 
Figure 1: DLX 5-stage pipeline architecture with FETCH stage highlighted 
Requirements 

1. The lab will be done in modular, hierarchical VHDL.  Your top module should be named 
something like “fetch” or “fetch_stage”. 
 
2. Implement the PC, Instruction Memory, Adder, Multiplexer, and appropriate registers as shown 
in Figure 1, with the modifications discussed in class. 
 
3. Design the Instruction Memory such that your <code>.mif files produced by your assembler can 
be loaded into the memory at synthesis time. 
 
4. Design appropriate Questa test-benches to exercise your FETCH stage.  Verify that your 
architecture successfully handles the 4 examples from the previous lab (example1, example2, 
example3, and factorial).  Exercise the two inputs to the system in a variety of ways. 
  
## Pass-off 
10 pts – Demonstrate to the instructor a Questa simulation of your factorial example.  Simulate 
branches and jumps in the appropriate spots in the code. 