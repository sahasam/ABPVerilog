import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import logging

class Bram_Testbench:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("bram_test.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 8, units='ns').start())
    
    async def reset_data(self):
        self.dut.we.value = 1
        self.dut.en.value = 1
        self.dut.data_in.value = 0x00
        for addr in range(64):
            self.dut.addr.value = addr
            await RisingEdge(self.dut.clk)

        self.dut.we.value = 0
        self.dut.en.value = 0
        await RisingEdge(self.dut.clk)
    
    async def set_data(self, data :bytes):
        if len(data) != 64:
            raise ValueError("data bytes is not the right size")
        
        self.dut.we.value = 1
        self.dut.en.value = 1
        for addr in range(64):
            self.dut.data_in.value = data[addr]
            self.dut.addr.value = addr
            await RisingEdge(self.dut.clk)
        
        self.dut.we.value = 0
        self.dut.en.value = 0
        await RisingEdge(self.dut.clk)
    
    async def read_and_check_data(self, data :bytes):
        if len(data) != 64:
            raise ValueError("data bytes is not the right size")
        
        self.dut.we.value = 0
        self.dut.en.value = 1
        self.dut.addr.value = 0x00
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        for addr in range(1,64):
            self.dut.addr.value = addr
            await RisingEdge(self.dut.clk)
            assert self.dut.data_out.value == data[addr-1]
        
        self.dut.we.value = 0
        self.dut.en.value = 0
        await RisingEdge(self.dut.clk)


@cocotb.test()
async def test_bram_read_write(dut):
    tb = Bram_Testbench(dut)
    await tb.reset_data()

    data_bytes = bytes(list(range(0,128,2)))
    await tb.set_data(data_bytes)

    await tb.read_and_check_data(data_bytes)




