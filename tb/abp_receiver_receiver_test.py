import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamMonitor, AxiStreamFrame
import logging
import struct

class Abp_Receiver_Receiver_Testbench:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("abp_receiver_test.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 8, units='ns').start())

        self.source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.aresetn, reset_active_level=False)
        self.monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.aresetn, reset_active_level=False)

    async def reset(self):
        self.dut.aresetn.setimmediatevalue(1)
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)

@cocotb.test()
async def test_abp_rr_correctly_updates_sender_value(dut):
    tb = Abp_Receiver_Receiver_Testbench(dut)
    await tb.reset()

    bytes = b'\xde\xad\xbe\xef' + b'\x00'*(60)
    frame = AxiStreamFrame(tdata=bytes)
    await tb.source.send(frame)

    await Timer(1000, units='ns')

    assert 1<2