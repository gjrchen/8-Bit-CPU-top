![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

## How it works

This project is a basic 8-bit CPU design building off the SAP-1. It was collaboratively designed as part of ECE 298A, a 10-student pilot course at the University of Waterloo aimed at integrating ASIC design into the ECE curriculum.

The control block is implemented using a 6 stage sequential counter for sequencing micro-instructions, and a LUT for corresponding op-code to operation(s).

The program counter enumerates all values between 0 and F (15) before looping back to 0 and starting again. The counter will clear back to 0 whenever the chip is reset.

The Instruction register stores the current instructions and breaks it up into the opcode and address, which are passed into corresponding locations

The 16 Byte memory module consists of 16 memory locations that store 1 byte each. The memory allows for both read and write operations, controlled by input signals, as well as data supplied by the MAR.

The MAR is a register which handles RAM interactions, namely specifying the address for store/load, as well as the data to be stored.

The 8-bit ripple carry adder assumes 2s complement inputs and thus supports addition and subtraction. It pushes the result to the bus via tri-state buffer. It also includes a zero flag and a carry flag to support conditional operation using an external microcontroller. These flags are synchronized to the rising edge of the clock and are updated when the adder outputs to the bus.

The Accumulator register functions to store the output of the adder. It is synchronized to the positive edge of the clock. The accumulator loads and outputs its value from the bus and is connected via tri-state buffer. The accumulator’s current value is always available as an output (and usually connected to the Register A input of the ALU)

The B register stores the second operand for ALU operations which is loaded from RAM.

The Output register outputs the value from register A onto the uo_out pins.

The 8 Bit Bus is driven by various blocks. We allow multiple blocks that are able to write using tri-state buffers.

## Supported Instructions

| **Mnemonic**  | **Opcode** | **Function**                                             |
| ------------- | ---------- | -------------------------------------------------------- |
| HLT           | 0x0        | Stop processing                                          |
| NOP           | 0x1        | No operation                                             |
| ADD {address} | 0x2        | Add B register to A register, leaving result in A        |
| SUB {address} | 0x3        | Subtract B register from A register, leaving result in A |
| LDA {address} | 0x4        | Put RAM data at {address} into A register                |
| OUT           | 0x5        | Put A register data into Output register and display     |
| STA {address} | 0x6        | Store A register data in RAM at {address}                |
| JMP {address} | 0x7        | Change PC to {address}                                   |

### Instruction Notes

- All instructions consist of an opcode (most significant 4 bits), and an address (least significant 4 bits, where applicable)

[For further details, read the documentation for project](docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.
