# DLX Pipeline Hazards
Dr. Jonathan Phillips
Utah State University
ECE 6930 – Advanced Reconfigurable Computing

## Overview
• Now that all 5
stages exist, is the
DLX processor fully
functional?
• No, we need to
account for
PIPELINE HAZARDS
• Data Hazards
• Control Hazards
• Expecting the
programmer to
insert NOPs is not
reasonable

## Data Hazards

• Hennessy & Patterson: “Data hazards arise when an instruction
depends on the results of a previous instruction in a way this is
exposed by the overlapping of instructions in the pipeline.”
• Data hazards create the need to STALL the pipeline.

## Data Hazard Classification

• RAW (read after write)
• Most common type of data hazard
• Example:
```
ADDI R10, R4, 1
ADD R11, R10, R10
```
• The pipeline has to wait for R10 to be written before it can be read
• How many stalls are needed to mitigate this hazard?

## Data Hazard Classification

• WAW (write after write)
• A later instruction tries to write a register or memory location before an
earlier instruction
• Do we need to account for WAW hazards in our DLX pipeline?
• WAR (write after read)
• A later instruction tries to write a destination before an earlier instruction is
done reading it
• Do we need to account for WAR hazards in our DLX pipeline?

## Minimizing Data Hazard Pipeline Stalls

• Forwarding – Fast-
tracking results to
minimize RAW
pipeline stalls
• Example 1
From Computer Architecture A Quantitative Approach, Hennessy & Patterson, 2nd Edition, 1995

## Minimizing Data Hazard Pipeline Stalls

• Forwarding – Fast-
tracking results to
minimize RAW
pipeline stalls
• Example 2
From Computer Architecture A Quantitative Approach, Hennessy & Patterson, 2nd Edition, 1995

## Minimizing Data Hazard Pipeline Stalls

• Forwarding – Fast-
tracking results to
minimize RAW
pipeline stalls
• Example 3
From Computer Architecture A Quantitative Approach, Hennessy & Patterson, 2nd Edition, 1995

## Minimizing Data Hazard Pipeline Stalls

• Forwarding – Fast-
tracking results to
minimize RAW
pipeline stalls
• Example 3 Solution
From Computer Architecture A Quantitative Approach, Hennessy & Patterson, 2nd Edition, 1995

## DLX Forwarding Rules for Data Hazard Mitigation Table

| Source instruction location | Source opcode | Destination instruction location | Destination opcode | Destination of forwarded result | Comparison (if equal then forward) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| EX/MEM | ALU | ID/EX | Register-register ALU, immediate ALU, load, store, branch | Top ALU input | EX/MEM(Rd) = ID/EX(Rs1) |
| EX/MEM | ALU | ID/EX | Register-register ALU | Bottom ALU input | EX/MEM(Rd) = ID/EX(Rs2) |
| MEM/WB | ALU | ID/EX | Register-register ALU, immediate ALU, load, store, branch | Top ALU input | MEM/WB(Rd) = ID/EX(Rs1) |
| MEM/WB | ALU | ID/EX | Register-register ALU | Bottom ALU input | MEM/WB(Rd) = ID/EX(Rs2) |
| MEM/WB | Load | ID/EX | Register-register ALU, immediate ALU, load, store, branch | Top ALU input | MEM/WB(Rd) = ID/EX(Rs1) |
| MEM/WB | Load | ID/EX | Register-register ALU | Bottom ALU input | MEM/WB(Rd) = ID/EX(Rs2) |

## DLX Architecture with Data Forwarding

From Computer Architecture A Quantitative Approach, Hennessy & Patterson, 2nd Edition, 1995

## Data Hazard Summary

• Forwarding can prevent some data hazards but not all
• A way to “pause” the pipeline must be created
• Is the “pause” as simple as not incrementing the PC?

## Control Hazards

• Hennessy & Patterson: “Control hazards arise from the pipelining of
branches and other instructions that change the PC.”
• Control Hazards can cause greater performance loss than data
hazards.
• Example:
J label
SUBI R20, R10, 5
ADDI R20, R20, 1
SLL R20, R20, R17
NOP
• How many cycles of stall does this sequence of instructions incur?

## How to handle branches

• Ideas
1. Stall the pipeline on every branch – simple but costly
2. Always assume branch not taken
1. Flush pipeline if assumption incorrect.
2. How often will the assumption be correct?
3. Always assume branch taken
1. Flush pipeline if assumption incorrect.
2. How often will the assumption be correct?
4. Branch prediction
1. Implies code profiling
• How long can “bad” instructions live in the pipeline?