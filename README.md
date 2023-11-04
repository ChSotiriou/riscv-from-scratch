# RISCV From Scratch

> Following the lessons from [BrunoLevy/learn-fpga](https://github.com/BrunoLevy/learn-fpga/)

## RISCV Instruction Set

> [RISCV Instruction Set Reference Manual](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)

- RISCV uses a modular instruction set

### RV32I - 32bit Base Integer Instruction Set

- 32x 32bit Registers - x0 to x31
    - x0 is the "zero register", hardwired to all zeros
- 1x 32bit PC Register
- Any x<n> register can be used as the stack pointer and base pointer
    - x1 -> Return Address
    - x2 -> Stack Pointer
- 11 Base instruction with varients for each one
- Page 130 of manual for instruction encoding
- Immidiate Value Encoding page 16