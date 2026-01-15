#include "structs.h"

void print_header(FILE* fo){
	fprintf(fo, "DEPTH = 1024;\n");
	fprintf(fo, "WIDTH = 32;\n");
	fprintf(fo, "ADDRESS_RADIX = HEX;\n");
	fprintf(fo, "DATA_RADIX = HEX;\n");
	fprintf(fo, "CONTENT;\n");
	fprintf(fo, "BEGIN;\n");
}

void print_footer(FILE* fo){
	fprintf(fo, "END");
}

int main(void){
	
	//opens input file
	FILE* fp = fopen("example1.dlx", "r");
	if(fp == NULL){
		printf("failed to open file\n");
		exit(1);
	}
	
	//opens output file
	FILE* fo = fopen("data1.mif", "w");
	if(fo == NULL){
		printf("failed to open file\n");
		exit(1);
	}
	
	//variables to help assemble file
	int data_flag = 0;
	int code_flag = 0;
	int addr = 0;
	int opcode_tracker = 0;
	char line[256];
	int done = 0;

	//grabs line by line from the input file
	while (fgets(line, sizeof(line), fp)) {
		//checks if there is a commment anywhere
		//files specify comments take the entire line
		//so if theres a ; anywhere the line is a comment
		char *comment = strchr(line, ';');
		
		//grabs a single token from the line that we just grabbed
		//second argument is delimiter that removes unwanted chars from token
		char *token = strtok(line, " ,\t\n\r");
		
		//This loop checks the current line for .data
		//if found it will turn on data_flag on to let the rest of the 
		//assembler know that it is reading data memory
		while (token != NULL && comment == 0 && data_flag == 0 && code_flag == 0) {
			if (strcmp(token, ".data") == 0){data_flag = 1;}	
			if (strcmp(token, ".text") == 0){code_flag=1;}
			token = strtok(NULL, " ,\t\n\r");
		}
		if(data_flag || code_flag)break;

	}
	
	print_header(fo);
	//grab line by line for the data section 
	label* data_labels;
	int num_data = 0;
	while(fgets(line,sizeof(line),fp) && data_flag == 1){
	
		char *comment = strchr(line, ';');
		char *token = strtok(line, " ,\t\n\r");
		
		//now that we're in the data section it is grabbing data
		if(token != NULL && data_flag == 1 && comment == 0){
			//stores tokens as different char* to print to file later
			char *variable = malloc(strlen(token) + 1);
			strcpy(variable, token);
			printf("%s \n", variable);
			if(strcmp(variable, ".text") == 0)break;
			data_labels = (label*)realloc(data_labels, sizeof(label)*(num_data+1));
			if(data_labels == NULL){
				printf("realloc failed!");
				exit(1);
			}
			data_labels[num_data].label = strdup(token);
			data_labels[num_data++].address = addr;
			
			token = strtok(NULL, " ,\t\n\r");
			char *length = malloc(strlen(token) + 1);
			strcpy(length, token);
			printf("%s \n", length);
			
			for(int i = 0; i < atoi(length); i++){
				token = strtok(NULL, " ,\t\n\r");
				char *value = malloc(strlen(token) + 1);
				strcpy(value, token);
				printf("%s \n", value);
				
				//This should print to a file but is not working. format is correct tho
				fprintf(fo, "%03X : %08X; --%s[%d]\n", addr++, atoi(value), variable, i);
			}
			done++;
		}
	}
	print_footer(fo);
	fclose(fo);
	
	FILE* fo2 = fopen("code1.mif", "w");
	if(fo2 == NULL){
		printf("failed to open file\n");
		exit(1);
	}
	
	
	
	fclose(fp);
	
	return(0);
}