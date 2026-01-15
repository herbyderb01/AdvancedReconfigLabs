#include <stdio.h> 
#include <stdlib.h>
#include <string.h>

typedef struct{
	const char *name;
	int hex;
}opcode;

typedef struct{
	const char *label;
	int address;
}label;

extern opcode opcodes[];