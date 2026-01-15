#include "structs.h"


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
	{"SRA", 0x16},
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

label* find_labels(char* dlx_file){
	label* labels;
	
	FILE* fp = fopen(dlx_file, "r");
	if(fp == NULL){
		printf("failed to open file\n");
		exit(1);
	}
	
	char line[256];
	int text_label = 0;
	
	while(fgets(line,sizeof(line),fp)){
		char *comment = strchr(line, ';');
		
		char* token = strtok(line, " ,\t\n\r");
		
		while(token != NULL && comment == 0){
			if(strcmp(token, ".text") == 0){break; text_label=1;}
			token = strtok(NULL," ,\t\n\r");
		}
		if(text_label)break;
	}
	
	int opcode_flag = 0;
	int addr = 0;
	while(fgets(line,sizeof(line), fp)){
		char* comment = strchr(line,';');
		char* token = strtok(line, " ,\t\n\r");
		
		for(int i = 0; i < 49 && comment == 0; i++){
			if(strcmp(token, opcodes[i].name) == 0){opcode_flag=1;}
		}
		if(!opcode_flag){
			labels = (label*)realloc(labels, sizeof(label)*(addr+1));
			labels[addr].label = strdup(token);
			labels[addr].address = addr++;
		}
	}
}