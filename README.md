## Related Repositories

[Digital](https://github.com/rtfmtom/Digital)  
[Life-Hack](https://github.com/rtfmtom/CPU)  
[Assembler]()  

## Table of Contents

- [About](#about)
- [Architecture](#architecture)
- [CPU](#cpu)
  - [The A-Instruction](#the-a-instruction)
    - [Dual Purpose A-Register](#dual-purpose-a-register)
  - [The C-Instruction](#the-c-instruction)
- [Usage](#usage)
  - [Remote Interface Usage](#remote-interface-usage)

# About

This project is an implementation of the "Hack" computer specification from Nisan & Schocken's _The Elements of Computing Systems_. 

All circuits were designed using [Digital](https://github.com/rtfmtom/Digital), an open-source digital logic designer and circuit simulator.

# Architecture

The `HackComputer` is a Harvard architecture computer, meaning that program memory and data memory are physically separate.[^1] 

[^1]: This is distinct from the more familiar Von Neumann architecture, in which program instructions and data share a unified memory space in RAM.

<img width="555" height="508" alt="Computer" src="https://github.com/user-attachments/assets/84cd90c5-d9dc-4923-9b1c-88e013d686c9" />

Program instructions are loaded onto the ROM (Read Only Memory) chip. On each clock cycle, the CPU program counter (`pc`) outputs the next instruction address (`A`) to the ROM, and that instruction is delivered to the CPU for processing.

The CPU can read from memory (`inM`) or write to memory (`outM`) when the "store" bit is set (`writeM`). The memory location is addressed by the `addressM` bus. The corresponding pins connect from CPU to RAM as follows:

* `outM` → `Din` (data in)
* `writeM` → `str` (store)
* `addressM` → `A` (address)
* `inM` ← `D` (data out)

Other instructions load values to and from registers within the CPU itself in preparation for further processing, and do not result in memory reads or writes at all. These CPU internals will be explored in greater depth below.

The `sel` (select) pin on the ROM and the `ld` (load data) pin on the RAM control when data is read out to the CPU on the `instruction` and `inM` buses respectively. In this implementation, these pins are always set high—instructions are continuously read from ROM, and the CPU itself chooses whether to use or ignore the data on the `inM` bus at any given time.

The `reset` signal sets the program counter back to 0.

# CPU
<img width="1215" height="650" alt="CPU" src="https://github.com/user-attachments/assets/daf00182-5936-4e15-a9fd-712be35a8a8e" />

The CPU is built using 2 registers (A & D), an Arithmetic Logic Unit (`alu16`), and the Program Counter (`pc`).

### The A-Instruction

Instructions flow in on a 16-bit wide bus and are decoded through a series of logic gates and multiplexers. Bits are indexed 0-15, with 15 being the most significant bit.

Bit 15 determines the instruction type: if low, it's an A-instruction; if high, it's a C-instruction. When bit 15 is low, the ALU and jump logic are bypassed, and bits 0-14 are treated as numeric data to be loaded into the A-Register.

An A-instruction is denoted in "Hack" assembly by the `@` symbol. For example, `@15` translates to `0x000F` in hexadecimal and `0b0000000000001111` in binary, loading the value 15 into the A-Register.[^2]

<img width="530" height="530" alt="A-Instruction" src="https://github.com/user-attachments/assets/b7f8fa12-6231-46a1-a8eb-c0157a9aadca" />

#### Dual Purpose A-Register

Incoming instructions are split and duplicated along two bus lines: the A Bus (treating bits 0-14 as data) and the C Bus (treating bits 0-14 as control signals). The enable pin (`en`) on the A-Register is controlled by an OR gate with one inverted input—the inverted input connects to bit 15, and the non-inverted input connects to bit 5 of the C Bus, creating the logic `5 OR (NOT 15)`.

This means the A-Register loads under two conditions: when bit 15 is low (an A-instruction), or when bit 15 is high and bit 5 is set (a C-instruction using the A-Register as a destination). This allows the A-Register to serve dual purposes: as the primary data register for A-instructions, and as an optional destination register for C-instructions.

[^2]: The A-Register holds 15 bits of data (bits 0-14). For _unsigned_ integers, this gives a range of 0 to 32,767. For _signed_ integers using two's complement, the range is -16,384 to 16,383.

### The C-Instruction

A C-instruction is performed when bit 15 is high and results in a computation. The generic form of a C-instruction in assembly is `[dest]=[computation]` or `[computation];[jump]`.

Jump instructions must be preceded by an A-instruction specifying the address in Program Memory (ROM) to jump to. A jump is triggered based on whether the computation evaluated to be greater than, less than, or equal to zero:
* `[computation];JEQ` → if `[computation]` == 0, jump
* `[computation];JLT` → if `[computation]` < 0, jump
* `[computation];JGT` → if `[computation]` > 0, jump

The following are examples of valid C-instructions:
```
D=A     // load the value stored in the A-Register to the D-Register
D=D+1   // increment the value stored in the D-Register

@10
0;JMP   // unconditional jump to instruction at address 10 in ROM

@4
D+A;JGT // jump to instruction at address 4 in ROM if D+A is greater than 0
```

Bit-wise, a C-instruction is encoded as:
```
0b111 1110000 010 000  // raw binary
0b111 a cccccc ddd jjj  // encoding
```

Going from most significant bit to least, this decodes as follows:
* `111` — Bits 15-13 are always set high. Bit 15 indicates this is a C-instruction. Bits 14 and 13 are unused and set high by convention.
* `a` — Bit 12 selects the ALU's second input: if low, use the A-Register; if high, use M (RAM[A]).
* `cccccc` — Bits 11-6 are control bits that determine what computation the ALU performs.
* `ddd` — Bits 5-3 control the destination(s) where the result is stored.
* `jjj` — Bits 2-0 designate the jump condition.

The destination for a computation can be any combination of: the A-Register, the D-Register, or the memory location addressed by the A-Register (RAM[A], denoted as `M` in Hack assembly).

The following tables provide a complete reference of `comp`, `dest`, and `jump` encodings.[^3]

[^3]: Tables adapted from Nisan & Shocken's _The Elements of Computing Systems: Building a Modern Computer from First Principles_

<table>
<tr>
<td valign="top">

| `a` == 0 | `a` == 1 |  |  |  |  |  |  |
|------|------|----|----|----|----|----|----|
| comp |      | c1 | c2 | c3 | c4 | c5 | c6 |
| 0    |      | 1  | 0  | 1  | 0  | 1  | 0  |
| 1    |      | 1  | 1  | 1  | 1  | 1  | 1  |
| -1   |      | 1  | 1  | 1  | 0  | 1  | 0  |
| D    |      | 0  | 0  | 1  | 1  | 0  | 0  |
| A    | M    | 1  | 1  | 0  | 0  | 0  | 0  |
| !D   |      | 0  | 0  | 1  | 1  | 0  | 1  |
| !A   | !M   | 1  | 1  | 0  | 0  | 0  | 1  |
| -D   |      | 0  | 0  | 1  | 1  | 1  | 1  |
| -A   | -M   | 1  | 1  | 0  | 0  | 1  | 1  |
| D+1  |      | 0  | 1  | 1  | 1  | 1  | 1  |
| A+1  | M+1  | 1  | 1  | 0  | 1  | 1  | 1  |
| D-1  |      | 0  | 0  | 1  | 1  | 1  | 0  |
| A-1  | M-1  | 1  | 1  | 0  | 0  | 1  | 0  |
| D+A  | D+M  | 0  | 0  | 0  | 0  | 1  | 0  |
| D-A  | D-M  | 0  | 1  | 0  | 0  | 1  | 1  |
| A-D  | M-D  | 0  | 0  | 0  | 1  | 1  | 1  |
| D&A  | D&M  | 0  | 0  | 0  | 0  | 0  | 0  |
| D\|A | D\|M | 0  | 1  | 0  | 1  | 0  | 1  |

</td>
<td valign="top">

| dest | d1 | d2 | d3 | Store comp in:          |
|------|----|----|----|---------------------------------|
| null | 0  | 0  | 0  | the value is not stored         |
| M    | 0  | 0  | 1  | RAM[A]                          |
| D    | 0  | 1  | 0  | D register (reg)                |
| DM   | 0  | 1  | 1  | D reg and RAM[A]                |
| A    | 1  | 0  | 0  | A reg                           |
| AM   | 1  | 0  | 1  | A reg and RAM[A]                |
| AD   | 1  | 1  | 0  | A reg and D reg                 |
| ADM  | 1  | 1  | 1  | A reg, D reg, and RAM[A]        |

| jump | j1 | j2 | j3 | Effect:                    |
|------|----|----|----|-----------------------------|
| null | 0  | 0  | 0  | no jump                     |
| JGT  | 0  | 0  | 1  | if *comp* > 0 jump          |
| JEQ  | 0  | 1  | 0  | if *comp* = 0 jump          |
| JGE  | 0  | 1  | 1  | if *comp* ≥ 0 jump          |
| JLT  | 1  | 0  | 0  | if *comp* < 0 jump          |
| JNE  | 1  | 0  | 1  | if *comp* ≠ 0 jump          |
| JLE  | 1  | 1  | 0  | if *comp* ≤ 0 jump          |
| JMP  | 1  | 1  | 1  | unconditional jump          |

</td>
</tr>
<td>When a == 0, use A register; when a == 1, use M (RAM[A])</td>
<td></td>
</table>

# Usage

User-defined circuits in Digital are saved as XML files with the `.dig` extension. Saved circuits are composable, meaning you can import one `.dig` file into another circuit to act as an embedded chip.

This repository contains all the `.dig` files necessary to build the Hack computer. To run it locally, clone this repository, open Digital, and select the `circuits/HackComputer.dig` file:

<img width="709" height="523" alt="Open" src="https://github.com/user-attachments/assets/c1662890-5b34-4d2a-85ff-239de9bc64db" />

I've included several programs for demonstration purposes in the `programs` directory. To load a program into the `HackComputer` circuit:

1. Right-click the `ROM` chip
2. Select 'Advanced'
3. Check 'Program Memory' and 'Reload model at start'
4. Use the `...` button to select a `.hex` file from the programs folder
5. Click `OK`

<img width="746" height="639" alt="Configure ROM" src="https://github.com/user-attachments/assets/ae1a2b28-f411-4e8c-ab63-eaa3f530b130" />

Once the program is loaded into ROM, you can execute it by clicking the 'Start' button.

While the program is running, you can inspect the `HackComputer`'s data memory by right-clicking the RAM chip:

<img width="876" height="657" alt="Inspect RAM" src="https://github.com/user-attachments/assets/0a81a4e4-375d-4586-ae19-7c698cfb4f03" />

In the example above, the program `SumToN.hex` computes the sum of the first `n` natural numbers (1+2+3+...+n). Here, `n=6` is stored at memory address `0x0000`. Address `0x0010` stores the iteration count of the program's main loop, and address `0x0011` serves as an accumulator for the running sum. The final result is stored at `0x0001`: hexadecimal `0x15`, or decimal 21.

### Remote Interface Usage

More exciting demonstrations of `HackComputer` programs can be run by utilizing the remote interface with [a slightly modified fork of Digital](https://github.com/rtfmtom/Digital).

This approach requires additional setup but opens up many more possibilities for experimentation, such as Conway's Game of Life:

<img width="1321" height="861" alt="Screenshot 2025-10-18 at 2 02 15 PM" src="https://github.com/user-attachments/assets/2f09863f-ddfc-4c15-8671-df6cd6116e1f" />

For more information on using the remote interface, please see [Life-Hack](https://github.com/rtfmtom/Life-Hack)

