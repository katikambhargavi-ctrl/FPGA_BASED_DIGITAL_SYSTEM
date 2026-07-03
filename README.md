Candidate Name: Bhargavi Katikam
Intern ID: CITS2263



# 32-bit RISC Processor using Verilog HDL

## Internship

This project was developed as part of the **CodTech Internship** to demonstrate the design and implementation of a **32-bit RISC Processor** using **Verilog HDL**. The processor integrates essential components such as the Program Counter, Instruction Memory, Register File, ALU, Data Memory, and Control Unit to execute a subset of RISC instructions.

---

## Project Overview

The **32-bit RISC Processor** is a simplified single-cycle processor capable of executing arithmetic, logical, memory access, and branch instructions. It demonstrates the basic architecture of a RISC CPU and illustrates how different hardware modules interact to complete instruction execution.

The processor includes instruction fetching, decoding, execution, memory access, and register write-back stages within a single clock cycle.

---

## Features

- 32-bit processor architecture
- Single-cycle processor design
- Modular Verilog implementation
- Program Counter (PC)
- Instruction Memory
- Register File (32 Registers)
- Arithmetic Logic Unit (ALU)
- ALU Control Unit
- Main Control Unit
- Sign Extension Unit
- Data Memory
- Branch Address Calculation
- Register Write-back Logic

---

## Supported Instructions

The processor currently supports the following instructions:

### R-Type Instructions
- ADD
- SUB
- AND
- OR
- SLT (Set Less Than)

### Memory Instructions
- LW (Load Word)
- SW (Store Word)

### Branch Instruction
- BEQ (Branch if Equal)

---

## Project Architecture

The processor consists of the following modules:

- risc_processor_32bit (Top Module)
- pc_reg
- instruction_memory
- control_unit
- register_file
- sign_extend
- alu_control_unit
- alu
- data_memory

---

## Module Description

### Program Counter (PC)
Maintains the address of the current instruction and updates it every clock cycle or resets to zero.

### Instruction Memory
Stores predefined machine instructions that are fetched based on the Program Counter.

### Control Unit
Generates all required control signals according to the instruction opcode.

### Register File
Contains 32 general-purpose 32-bit registers with dual read ports and one write port.

### Sign Extension Unit
Converts 16-bit immediate values into 32-bit signed values.

### ALU Control Unit
Generates ALU control signals using ALUOp and function fields.

### Arithmetic Logic Unit (ALU)
Performs arithmetic and logical operations including:
- Addition
- Subtraction
- AND
- OR
- Set Less Than (SLT)

It also generates the Zero flag used for branch decisions.

### Data Memory
Provides memory read and write operations for LW and SW instructions.

---

## Instruction Flow

1. Fetch instruction from Instruction Memory.
2. Decode instruction using the Control Unit.
3. Read operands from Register File.
4. Generate ALU control signals.
5. Execute ALU operation.
6. Access Data Memory if required.
7. Write result back to Register File.
8. Update Program Counter for the next instruction.

---

## Sample Instructions Included

The instruction memory is initialized with the following operations:

| Address | Instruction |
|---------|-------------|
| 0 | ADD R3, R1, R2 |
| 1 | SUB R4, R1, R2 |
| 2 | AND R5, R1, R2 |
| 3 | OR R6, R1, R2 |
| 4 | LW R7, 4(R1) |
| 5 | SW R7, 8(R1) |
| 6 | BEQ R1, R2, Offset |

---

## ALU Operations

| ALU Control | Operation |
|------------|-----------|
| 0000 | AND |
| 0001 | OR |
| 0010 | ADD |
| 0110 | SUB |
| 0111 | SLT |

---

## Tools Used

- Verilog HDL
- Xilinx Vivado 
- Digital Logic Design Concepts

---
