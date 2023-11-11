# RISCV From Scratch

> Following the lessons from [BrunoLevy/learn-fpga](https://github.com/BrunoLevy/learn-fpga/)

## SOC Datasheet

## Memory Map

Address Start | Address End | Description
--------------|-------------|-------------
0x00000000    | 0x00000400  | RAM
0x00400004    | 0x00400007  | GPIO (Outputs)

## RISCV Instruction Set

> [RISCV Instruction Set Reference Manual](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)

- RISCV uses a modular instruction set

### RV32I - 32bit Base Integer Instruction Set

- 32x 32bit Registers - x0 to x31
    - x0 is the "zero register", hardwired to all zero
- Registers have a specific function in the [ABI](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)

Register | ABI Name | Description
---|---|---
x0|zero|Hard-Wired Zero
x1|ra|Return Address
x2|sp|Stack Pointer
x3|gp|Global Pointer
x4|tp|Thread Pointer
x5|t0|Temporary Register
x6|t1|Temporary Register
x7|t2|Temporary Register
x8|s0|Saved Register / Frame Pointer
x9|s1|Saved Register
x10|a0|Function Argument 0 / Return Value
x11|a1|Function Argument 1
x12|a2|Function Argument 2
x13|a3|Function Argument 3
x14|a4|Function Argument 4
x15|a5|Function Argument 5
x16|a6|Function Argument 6
x17|a7|Function Argument 7
x18|s2|Saved Register
x19|s3|Saved Register
x20|s4|Saved Register
x21|s5|Saved Register
x22|s6|Saved Register
x23|s7|Saved Register
x24|s8|Saved Register
x25|s9|Saved Register
x26|s10|Saved Register
x27|s11|Saved Register
x28|t3|Temporary Register
x29|t4|Temporary Register
x30|t5|Temporary Register
x31|t6|Temporary Register
