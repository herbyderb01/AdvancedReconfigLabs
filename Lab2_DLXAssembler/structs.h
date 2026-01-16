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