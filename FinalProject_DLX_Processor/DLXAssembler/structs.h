/* =============================================================================
 * structs.h  --  Shared types for the DLX assembler
 * =============================================================================
 *
 *  opcode  -- (mnemonic, 6-bit opcode value) pair. The opcodes[] table in
 *             find_labels.c is an array of these.
 *
 *  label   -- (label name, absolute address) pair. find_labels() returns a
 *             dynamically-allocated array of these for Pass 2 to look up.
 * =============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct{
	const char *name;
	int hex;
}opcode;

typedef struct{
	char *label;
	int address;
}label;

extern opcode opcodes[];

label* find_labels(char* dlx_file, int* label_count);