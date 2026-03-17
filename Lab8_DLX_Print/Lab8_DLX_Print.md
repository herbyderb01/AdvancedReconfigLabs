# Advanced Reconfigurable Computing DLX Print Requirements

## Introduction

Your task is to (1) add 3 DLX instructions to the assembler and the architecture and (2) instantiate your
DLX processor on the Intel DE10-Lite development board. The three instructions are PCH (print
character to screen via UART), PD (print signed decimal integer to screen via UART), and PDU (print
unsigned decimal integer to screen via UART).

## Requirements

1. The opcodes for the 3 new instructions are as follows:
	
	a. PCH – 0x31 (6 bits)
	
	b. PD – 0x32 (6 bits)
	
	c. PDU – 0x33 (6 bits)

2. Usage is as follows:
	
	a. `PCH rs ;print character to screen`
	
	b. `PD rs ;print signed decimal integer to screen`
	
	c. `PDU rs ;print unsigned decimal integer to screen`

3. The assembler should also handle the new `.const` segment in the DLX file, as described in class. This segment is where length-preceded string constants will be declared.

4. Implement the correct functionality in the decode and execute stages of the DLX pipeline, as discussed in class, to handle these three new instructions and the new `.const` segment.

## Pass-off

20 points – Demonstrate that your assembler and DLX architecture can (1) produce a system that can
actually be placed on the FPGA for 10 points and (2) successfully execute (on the FPGA) a modified
version of your factorial program for an additional 10 points, in which the initial number is hard-coded in
the `.data` segment, the result is stored in the .data segment, and the result is also printed to the screen
via UART, along with an informative string. Below is an example output that could appear on the PuTTY
terminal:

```
Welcome to the DLX factorial program!
6! = 720
```

Be prepared to edit the input value in the DLX program and have the output change appropriately
during pass-off.