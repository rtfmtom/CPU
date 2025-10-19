// Program: Computes the sum 1 + 2 + 3 + ... + RAM[0] and stores result in RAM[1]
// RAM[0]:  N
// RAM[1]:  RESULT
// RAM[16]: COUNTER
// RAM[17]: ACCUMULATOR

// Initialize N to 6
@6
D=A
@0
M=D

// Initialize COUNTER & ACCUMULATOR
@16
M=1
@17
M=0

// LOOP:

// If COUNTER - N > 0, EXIT (Jump to instruction 25)
@16
D=M
@0
D=D-M
@25
D;JGT

// Else, ACCUMULATOR = ACCUMULATOR + COUNTER
@17
D=M
@16
D=D+M
@17
M=D

// COUNTER++
@16
D=M
M=D+1

// Jump to LOOP (line 8)
@8
0;JMP

// EXIT:
// RESULT = ACCUMULATOR
@17
D=M
@1
M=D

// HALT (infinite loop)
@29
0;JMP