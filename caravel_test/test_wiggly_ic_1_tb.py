import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, with_timeout

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

import png
from datetime import datetime


# takes ~60 seconds on my PC
async def reset(dut):
    clock = Clock(dut.clk, 25, units="ns")
    cocotb.fork(clock.start())
    
    dut.RSTB.value = 0
    dut.power1.value = 0;
    dut.power2.value = 0;
    dut.power3.value = 0;
    dut.power4.value = 0;

    await ClockCycles(dut.clk, 8)
    dut.power1.value = 1;
    await ClockCycles(dut.clk, 8)
    dut.power2.value = 1;
    await ClockCycles(dut.clk, 8)
    dut.power3.value = 1;
    await ClockCycles(dut.clk, 8)
    dut.power4.value = 1;

    await ClockCycles(dut.clk, 80)
    dut.RSTB.value = 1

    # wait for the project to become active
    # await with_timeout(RisingEdge(dut.uut.mprj.wrapped_wiggly_ic_.active), 180, 'us')
    # await RisingEdge(dut.uut.mprj.wrapped_rgb_mixer_0.active)

# @cocotb.test()
# async def test_wiggly_ic_1_tb(dut):
#     await test_wiggly_ic_1(dut)


H_RES = 640
V_RES = 480

def write_png(filename, screenbuffer):
    f = open(filename, 'wb')
    w = png.Writer(H_RES, V_RES, greyscale=False)
    w.write_array(f, screenbuffer)
    f.close()

@cocotb.test()
async def test_wiggly_ic_1_tb(dut):
    def info(fmt, *args):
        dut._log.info("%s\t" + fmt, datetime.now(), *args)

    await reset(dut)

    clk = Clock(dut.clk, 60, units="ns")  # 60ns period = 16.6MHz
    cocotb.fork(clk.start())  # Start the clock

    vga_clk_pix = Clock(dut.vga_clk_pix, 40, units="ns") # 40ns period = 25MHz
    cocotb.fork(vga_clk_pix.start())

    info("hello")

    await Timer(500, units="ns")  # wait a bit

    screenbuffer = [0]*(H_RES*V_RES*3)
    def index(x, y): return (y*H_RES + x) * 3

    async def read_frame(frame_num):
        await RisingEdge(dut.vga_vsync)
        
        while True:
            await FallingEdge(dut.vga_clk_pix)
            if dut.uut.mprj.wrapped_wiggly_ic_1_11.wiggly_ic_1_inst.vga_de.value == 1:
                i = (dut.uut.mprj.wrapped_wiggly_ic_1_11.wiggly_ic_1_inst.vga_sy.value*H_RES + dut.uut.mprj.wrapped_wiggly_ic_1_11.wiggly_ic_1_inst.vga_sx.value) * 3
                screenbuffer[i] = dut.vga_r.value << 6
                screenbuffer[i+1] = dut.vga_g.value << 6
                screenbuffer[i+2] = dut.vga_b.value << 6

            if dut.vga_vsync.value == 0:
                break

        info('frame %d', frame_num)
        write_png('frame' + str(frame_num) + '.png', screenbuffer)

        assert screenbuffer[index(2, 2)] == 0b11 << 6

        # blue cursor
        info("mouse_x=%d, mouse_y=%d", dut.mouse_x.value, dut.mouse_y.value)
        cursor = index(dut.uut.mprj.wrapped_wiggly_ic_1_11.wiggly_ic_1_inst.mouse_x.value + 2, dut.uut.mprj.wrapped_wiggly_ic_1_11.wiggly_ic_1_inst.mouse_y.value + 2)
        assert screenbuffer[cursor] == 0b00 << 6
        assert screenbuffer[cursor + 1] == 0b00 << 6
        assert screenbuffer[cursor + 2] == 0b11 << 6

    await read_frame(0)

    cocotb.fork(mouse_tester(dut))
    # wait until mouse movement has registered
    await Timer(3000, units="us")

    # now read next frame
    await read_frame(1)
