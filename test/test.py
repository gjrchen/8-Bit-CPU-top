# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.vaue = 0
    dut._log.info("Reset")
    await ClockCycles(dut.clk, 30)
    dut.rst_n.value = 1

    dut._log.info("Test NOP")
    dut.opcode.value = 1
    await ClockCycles(dut.clk, 1000)
    assert dut.uo_out.value == 0b00000000

    dut._log.info("Test ADD")
    dut.opcode.value = 2
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test SUB")
    dut.opcode.value = 3
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test LDA")
    dut.opcode.value = 4
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test OUT")
    dut.opcode.value = 5
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test STA")
    dut.opcode.value = 6
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test JMP")
    dut.opcode.value = 7
    await ClockCycles(dut.clk, 1000)

    dut._log.info("Test HLT")
    dut.opcode.value = 0
    await ClockCycles(dut.clk, 1000) 
