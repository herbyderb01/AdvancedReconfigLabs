# Advanced Reconfigurable Computing Final Project Requirements – Spring 2026

## Introduction

Your task is to (a) optimize your USU-DLX processor and (b) successfully execute two programs during the final competition. You will work in lab groups.

## Requirements

1. Optimize your USU-DLX pipeline to run as fast as possible. The clock frequency for the pipeline
must be a multiple of 1 MHz. Ideas for optimization include the following:
a. Maximize the operating clock frequency
b. Optimize your branch prediction algorithm
c. Minimize stall cycles needed to mitigate data hazards
d. Allow out-of-order execution
e. Optimize opcode encoding

The “Performance” section of the grading rubric will be scored on how well your processor runs compared to others. The top team gets 20 points, second place gets 19.5, third place 19, etc. If your processor doesn’t run, you get zero points for the “Performance” section.

2. Implement a “stopwatch” timer as a peripheral to your DLX processor for measuring execution time. The stopwatch should behave similar to the version you implemented in the first semester of Reconfigurable Computing:
   
a. The stopwatch should be accurate to hundredths of a second
b. The 6 seven-segment displays on the DE-10 Lite board will be used to represent
minutes, seconds, and hundredths of seconds following the format MM.SS.hh (notice
the decimal points)
c. Create 3 new DLX instructions for controlling the stopwatch. None of these opcodes need any operands:

i. TR: “Timer reset” sets the timer back to zero
ii. TGO: “Timer go” starts the timer
iii. TSP: “Timer stop” pauses the timer

## Pass-off

On Friday, April 24 at 1:30 p.m. (the scheduled final exam time for the course) two test programs (.dlx) will be posted on Canvas. For each program, you must show (1) the final time on your stopwatch and (2) that your program produces the correct result on the serial terminal. All pass-offs must happen before 3:20 p.m. (the end of the final exam period).

## Report

Complete a lab report that complies with the requirements listed in the “Assignment Grading Rubric” available on the main Canvas page. The report is due at 11:59 p.m. on Friday, April 24.

## Grading

You can get partial credit on the project even if it is not 100% functional. Here is the breakdown:

| Feature | Points |
|---------|--------|
| Print statements are functional | 10 |
| Scan statements are functional | 10 |
| Stopwatch is functional | 20 |
| Entire system is operational (i.e. runs both test programs correctly) | 20 |
| Performance (relative to other groups) | 20 |
| Report | 20 |
| TOTAL | 100 |