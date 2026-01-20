```bash
# Compile the assembler
gcc -o dlx_asm Assembler.c find_labels.c

# Run the assembler for example1.dlx
./dlx_asm example1.dlx data1_passOff.mif code1_passOff.mif

# Run the assembler for example2.dlx
./dlx_asm example2.dlx data2_passOff.mif code2_passOff.mif

# Run the assembler for example3.dlx
./dlx_asm example3.dlx data3_passOff.mif code3_passOff.mif

# Run the assembler for factorial.dlx
./dlx_asm factorial.dlx factorial_data_passOff.mif factorial_code_passOff.mif
```
