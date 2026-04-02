# DLX Assembler Documentation

## High-Level Explanation: The Two-Pass Assembler

At its core, this program is a **two-pass assembler**. It reads your assembly source code twice to translate it into machine code. This two-pass approach is a classic and effective way to solve the "forward reference" problem.

Imagine you have a `JUMP` instruction that needs to go to a label named `my_label`, but `my_label` is defined later in the file. When the assembler first sees the `JUMP`, it doesn't know the memory address for `my_label` yet.

This is why two passes are needed:

1.  **Pass 1 (Reconnaissance):** The first pass scans through the entire code section (`.text`) with one primary goal: to build a symbol table. This table is a list of all the labels (`top`, `loop`, `exit`, etc.) and the memory address where each is located. It doesn't generate any machine code; it just maps out the territory.

2.  **Pass 2 (Translation):** The second pass does the actual work of translation. It reads the source file again, line by line. This time, because it has the complete symbol table from Pass 1, it can translate every instruction into its 32-bit hexadecimal equivalent. When it encounters a `JUMP` or `BRANCH` to `my_label`, it simply looks up the address in the symbol table and plugs it into the machine code.

Finally, the assembler also handles the `.data` section by parsing variable definitions and writing their initial values to a separate data file, as required by the project.

---

## Detailed Code Explanation

Here is a walk-through of the execution flow of the C code.

### File: `find_labels.c`

This file is responsible for **Pass 1**.

-   **`opcodes[]` Array:** This global array acts as a dictionary of all valid DLX instructions and their corresponding 6-bit numerical opcodes. It's used to differentiate between an instruction (like `ADD`) and a label (like `loop`).

-   **`find_labels()` Function:**
    1.  It opens the source `.dlx` file.
    2.  It reads the file line by line, searching for the `.text` directive, ignoring everything until it enters the code segment.
    3.  Once inside the `.text` segment, it initializes an address counter to `0`.
    4.  It continues reading line by line, breaking each line into tokens (words).
    5.  For each token, it checks if the token is a valid instruction by comparing it against the `opcodes` array.
        -   If the token **is an instruction**, it means we've found a line of code, so it increments the address counter and moves on to the next line.
        -   If the token **is not an instruction**, it's assumed to be a **label**. The function records the label's name and the current value of the address counter into a `label` struct.
    6.  After reading the whole file, it returns a complete list of all labels found in the code and their addresses.

### File: `Assembler.c`

This file contains the main logic and performs **Pass 2**.

-   **`main()` Function - Setup:**
    -   It verifies that the user provided the correct command-line arguments.
    -   It calls `find_labels()` to get the symbol table (the list of all code labels) from Pass 1.

-   **Data Segment Processing:**
    -   It rewinds to the beginning of the source file and looks for the `.data` directive.
    -   Once in the `.data` section, it parses each line, expecting the format: `<name> <size> <value1> <value2> ...`.
    -   It adds the variable's name (e.g., `n`) to a master symbol table (`all_labels`) along with its starting memory address.
    -   It then reads the initial values and writes them in hexadecimal format to the output `.mif` data file. This process stops as soon as it encounters the `.text` directive.

-   **Pass 2 - Code Generation:**
    -   The program rewinds to the beginning of the source file one last time and seeks to the `.text` section.
    -   It reads the code line by line, initializing a code address counter to `0`.
    -   For each line, it identifies the instruction (e.g., `ADDI`, `LW`, `J`) and enters a large `if-else if` block to handle the specific **instruction format** (R-type, I-type, J-type, etc.).
    -   **This is the critical part:** Based on the format, it parses the operands (registers, immediate values, or labels).
        -   `get_register()` is used to convert `"R5"` into the number `5`.
        -   `get_value()` is used to get an operand's value. It's smart enough to first check if the operand is a label (looking it up in `all_labels`) and, if not, to convert it as a number.
    -   Using bitwise shifting (`<<`) and ORing (`|`), it assembles the final 32-bit instruction by placing the opcode and operand values into their correct bit positions.
    -   Finally, it writes the address and the 32-bit hexadecimal instruction to the output `.mif` code file, along with the original assembly line as a comment.

-   **Cleanup:**
    -   At the end, it closes all files and frees the memory that was dynamically allocated for the label list to prevent memory leaks.
