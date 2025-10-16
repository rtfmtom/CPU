This project is an implementation of the "Hack" computer specification from Nisan & Shocken’s _The Elements of Computing Systems_.

# Harvard architecture

The Harvard architecture is a variant on the Von Neumann machine where program memory and data memory are separate.

<img width="555" height="508" alt="Computer" src="https://github.com/user-attachments/assets/84cd90c5-d9dc-4923-9b1c-88e013d686c9" />

Program instructions are loaded onto the ROM (Read Only Memory) chip. On each clock cycle, the CPU program counter (`pc`) selects the next instruction address (`A`) on the ROM to be executed, and that instruction is delivered to the CPU for processing. 

The CPU can read from memory (`inM`) or write to memory (`outM`) if the "store" bit is set (`writeM`). The particular memory location is addressed by the `addressM` bus. The corresponding pins connect from CPU to RAM as follows:

* `outM` --> `Din` (data in)
* `writeM` --> `str` (store)
* `addressM` --> `A` (address)
* `inM` <-- `D` (data out)

Other instructions load values to and from registers on the CPU itself in preparation for further processing, and do not result in reads or writes to memory at all. This involves CPU internals that will be explored in greater depth below.

The `sel` (select) pin on the ROM and the `ld` (load data) pin on the RAM control when data is read out to the CPU on the `instruction` and `inM` buses respectively. In our case, these are always set to high—instructions are continuously read from ROM, and the CPU itself chooses whether to use or ignore the data on the `inM` bus at any given time.

The `reset` signal sets the program counter back to 0.

# CPU
<img width="1215" height="650" alt="CPU" src="https://github.com/user-attachments/assets/daf00182-5936-4e15-a9fd-712be35a8a8e" />

The CPU is built using 2 registers (A & D), an Arithmetic Logic Unit (`alu16`), and the Program Counter (`pc`).

### A Instructions

Instructions flow in on a 16-bit wide bus and are decoded. Bits are indexed 0-15, with 15 being the most significant bit.

Bit 15 controls whether the instruction loads data into the A-Register (an A-instruction) or performs a computation (a C-instruction). If bit 15 is low, the enable pin on the A-Register is activated, the ALU is bypassed, and any jump logic (controlled by bits 0-2) is ignored. Bits 0-14 are treated as numeric data and loaded into the A-Register.

An A-instruction is denoted in "Hack" assembly by the `@` symbol. For example, `@15` translates to `0x000F` in hexadecimal and `0b0000000000001111` in binary, loading the value 15 into the A-Register.

<img width="763" height="736" alt="A Instruction" src="https://github.com/user-attachments/assets/c972e866-b977-42b0-8cc8-e2d3b2ea7f46" />

### C Instructions
When bit 15 is high a computation, or C Instruction, is performed. 

# ALU
<img width="1112" height="529" alt="ALU" src="https://github.com/user-attachments/assets/c75d5c5e-68de-42e9-81cd-143efb9a7e92" />

# Program Counter
<img width="752" height="508" alt="PC" src="https://github.com/user-attachments/assets/1faa5329-4e09-48a5-8299-c8be68b22a8d" />

