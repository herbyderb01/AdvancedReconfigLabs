#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include "structs.h"

// This array defines all the DLX instructions that the assembler recognizes.
// Each entry contains the instruction's mnemonic (e.g., "ADD") and its corresponding 6-bit opcode in hexadecimal.
opcode opcodes[] = {
{"NOP", 0x00},
{"LW", 0x01},
{"SW", 0x02},
{"ADD", 0x03},
{"ADDI", 0x04},
{"ADDU", 0x05},
{"ADDUI", 0x06},
{"SUB", 0x07},
{"SUBI", 0x08},
{"SUBU", 0x09},
{"SUBUI", 0x0A},
{"AND", 0x0B},
{"ANDI", 0x0C},
{"OR", 0x0D},
{"ORI", 0x0E},
{"XOR", 0x0F},
{"XORI", 0x10},
{"SLL", 0x11},
{"SLLI", 0x12},
{"SRL", 0x13},
{"SRLI", 0x14},
{"SRA", 0x15},
{"SRAI", 0x16},
{"SLT", 0x17},
{"SLTI", 0x18},
{"SLTU", 0x19},
{"SLTUI", 0x1A},
{"SGT", 0x1B},
{"SGTI", 0x1C},
{"SGTU", 0x1D},
{"SGTUI", 0x1E},
{"SLE", 0x1F},
{"SLEI", 0x20}, 
{"SLEU", 0x21},
{"SLEUI", 0x22},
{"SGE", 0x23},
{"SGEI", 0x24}, 
{"SGEU", 0x25},
{"SGEUI", 0x26},
{"SEQ", 0x27},
{"SEQI", 0x28},
{"SNE", 0x29},
{"SNEI", 0x2A},
{"BEQZ", 0x2B},
{"BNEZ", 0x2C},
{"J", 0x2D},
{"JR", 0x2E},
{"JAL", 0x2F},
{"JALR", 0x30}
};

/**
 * @brief This function performs the first pass of the assembler.
 * 
 * Its primary purpose is to find all the labels within the .text (code) segment
 * of the DLX assembly file and record their addresses. These addresses are crucial
 * for resolving jumps and branches in the second pass.
 * 
 * @param dlx_file The path to the input DLX assembly file.
 * @param label_count A pointer to an integer that will be updated with the number of labels found.
 * @return A dynamically allocated array of `label` structs, each containing a label name and its address.
 */
label* find_labels(char* dlx_file, int* label_count) {
    label* labels = NULL;
    *label_count = 0;
    
    FILE* fp = fopen(dlx_file, "r");
    if(fp == NULL){
        printf("failed to open file %s\n", dlx_file);
        exit(1);
    }
    
    char line[256];
    int in_text_segment = 0;
    
    // First, we need to find the beginning of the .text segment.
    // We'll read the file line by line until we find the ".text" directive.
    while(fgets(line, sizeof(line), fp)) {
        // Remove comments from the line to avoid parsing them.
        char *comment = strchr(line, ';');
        if (comment) *comment = '\0';

        // Tokenize the line to find the .text directive.
        char* token = strtok(line, " ,\t\n\r");
        while(token != NULL) {
            if(strcmp(token, ".text") == 0) {
                in_text_segment = 1;
                break; 
            }
            token = strtok(NULL, " ,\t\n\r");
        }
        if(in_text_segment) break; // Exit the loop once .text is found.
    }
    
    if (!in_text_segment) {
        printf("No .text segment found\n");
        // It's valid for a file to have no code, so we just return.
        fclose(fp);
        return NULL;
    }
    
    // Now that we are in the .text segment, we can start counting addresses and finding labels.
    int addr = 0;
    while(fgets(line, sizeof(line), fp)) {
        char *comment = strchr(line, ';');
        if (comment) *comment = '\0'; // Truncate at comment

        char* token = strtok(line, " ,\t\n\r");
        if (token == NULL) continue; // Skip empty lines.
        
        // A line in the .text segment can contain a label, an instruction, or both.
        // We process tokens from left to right.
        while (token != NULL) {
            int is_opcode = 0;
            // Check if the token is a recognized instruction mnemonic.
            for(int i = 0; i < 49; i++) {
                if(strcmp(token, opcodes[i].name) == 0) {
                    is_opcode = 1;
                    break;
                }
            }
            
            if (is_opcode) {
                // If we found an opcode, this line contains an instruction.
                // We increment the address counter and stop parsing this line,
                // as anything after the opcode is an operand.
                addr++;
                break; 
            } else {
                // If the token is not an opcode, it must be a label.
                // We allocate memory for the new label and store its name and current address.
                labels = (label*)realloc(labels, sizeof(label) * (*label_count + 1));
                if (labels == NULL) {
                    printf("Memory allocation failed\n");
                    exit(1);
                }
                labels[*label_count].label = strdup(token);
                labels[*label_count].address = addr;
                (*label_count)++;
                // A label can be on the same line as an instruction, so we continue to the next token.
            }
            token = strtok(NULL, " ,\t\n\r");
        }
    }
    
    fclose(fp);
    return labels; // Return the array of found labels.
}
