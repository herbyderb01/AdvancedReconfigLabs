# Advanced Reconfigurable Computing DLX Scan Requirements

## Introduction

Your task is to add 2 DLX instructions to the assembler and the architecture and instantiate your new DLX processor on the Intel DE10-Lite development board. The two instructions are GD (get signed decimal integer from keyboard via UART) and GDU (get unsigned decimal integer from keyboard via UART).

## Requirements

1. The opcodes for the 2 new instructions are as follows:
   
	a. GD – `0x34` (6 bits)
	
	b. GDU – `0x35` (6 bits)

2. Usage is as follows:
   
	a. `GD rd ;get signed decimal integer from the keyboard`
	
	b. `GDU rd ;get unsigned decimal integer from the keyboard`

3. Implement the correct functionality in the DLX pipeline, as discussed in class, to handle these new instructions.

## Pass-off

10 points – Demonstrate that your assembler and DLX architecture can successfully execute (on the
FPGA) a modified version of your factorial program in which the initial number is input from the
keyboard via UART and the result is printed to the screen via UART, along with an informative string.
Below is an example output that could appear on the PuTTY terminal (the 6 after "Enter a number: " line indicates information
supplied by the user):

```
Welcome to the DLX factorial program!
Enter a number: 6
6! = 720
```

Run the program multiple times with different inputs to demonstrate correct behavior.
