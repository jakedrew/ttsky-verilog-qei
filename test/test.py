# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

SETTLE = 8

def cnt7(uo):
    return int(uo) & 0x7F

def dirbit(uo):
    return (int(uo) >> 7) & 1

def full15(uo, uio):
    return ((int(uio) & 0xFF) << 7) | (int(uo) & 0x7F)

async def drive_ab(dut, a, b):
    # drive ui_in[1:0] = {B:A}, leave other inputs 0
    dut.ui_in.value = (int(dut.ui_in.value) & ~0x3) | ((b & 1) << 1) | (a & 1)
    await ClockCycles(dut.clk, SETTLE)

async def fwd_cycle(dut):
    await drive_ab(dut, 0, 1)  # 00->01
    await drive_ab(dut, 1, 1)  # 01->11
    await drive_ab(dut, 1, 0)  # 11->10
    await drive_ab(dut, 0, 0)  # 10->00

async def bwd_cycle(dut):
    await drive_ab(dut, 1, 0)  # 00->10
    await drive_ab(dut, 1, 1)  # 10->11
    await drive_ab(dut, 0, 1)  # 11->01
    await drive_ab(dut, 0, 0)  # 01->00

@cocotb.test()
async def test_project(dut):
    # 100 kHz clock
    cocotb.start_soon(Clock(dut.clk, 10, units="us").start())

    # reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, SETTLE)

    # align to 00
    await drive_ab(dut, 0, 0)

    # forward x4: expect +1 on LSBs each sub-step, DIR=1
    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 0, 1)
    assert cnt7(dut.uo_out.value) == ((before + 1) & 0x7F) and dirbit(dut.uo_out.value) == 1

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 1, 1)
    assert cnt7(dut.uo_out.value) == ((before + 1) & 0x7F) and dirbit(dut.uo_out.value) == 1

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 1, 0)
    assert cnt7(dut.uo_out.value) == ((before + 1) & 0x7F) and dirbit(dut.uo_out.value) == 1

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 0, 0)
    assert cnt7(dut.uo_out.value) == ((before + 1) & 0x7F) and dirbit(dut.uo_out.value) == 1

    # backward x4: expect -1 each sub-step, DIR=0
    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 1, 0)
    assert cnt7(dut.uo_out.value) == ((before - 1) & 0x7F) and dirbit(dut.uo_out.value) == 0

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 1, 1)
    assert cnt7(dut.uo_out.value) == ((before - 1) & 0x7F) and dirbit(dut.uo_out.value) == 0

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 0, 1)
    assert cnt7(dut.uo_out.value) == ((before - 1) & 0x7F) and dirbit(dut.uo_out.value) == 0

    before = cnt7(dut.uo_out.value)
    await drive_ab(dut, 0, 0)
    assert cnt7(dut.uo_out.value) == ((before - 1) & 0x7F) and dirbit(dut.uo_out.value) == 0

    # +256 counts using pins=
    start15 = full15(dut.uo_out.value, dut.uio_out.value)
    for _ in range(64):
        await fwd_cycle(dut)
    end15 = full15(dut.uo_out.value, dut.uio_out.value)
    assert ((end15 - start15) & 0x7FFF) == 256
