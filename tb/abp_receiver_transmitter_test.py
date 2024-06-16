import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, First
from cocotb.result import TestFailure
from cocotbext.axi import AxiStreamFrame, AxiStreamBus, AxiStreamSink, AxiStreamMonitor
import logging
import random

class Abp_Receiver_Transmitter_Testbench:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("abp_receiver_test.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 8, units='ns').start())

        self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.aresetn, reset_active_level=False)
        self.monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.aresetn, reset_active_level=False)

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


@cocotb.coroutine
async def timeout_coroutine(timeout_time):
    await Timer(timeout_time, units='ns')
    raise TestFailure(f"Test timed out after {timeout_time} ns")


@cocotb.test()
async def test_abp_rt_initial_ack_frame(dut):
    tb = Abp_Receiver_Transmitter_Testbench(dut)
    dut.alternating_bit.value = 0
    await tb.reset()

    # Verify ACK is generating properly and repeats as long as no inputs are changed.
    ack_frame_task = cocotb.start_soon(tb.sink.recv())
    timeout_task = cocotb.start_soon(timeout_coroutine(5000))
    ack_frame = await First(ack_frame_task.join(), timeout_task.join())
    if ack_frame is timeout_task.join():
        raise TestFailure("Test ended due to timeout")

    expected_frame = AxiStreamFrame(tdata=b'\x00'*64)
    assert ack_frame.tdata == expected_frame.tdata


@cocotb.test()
async def test_abp_rt_resends_ack_frame_after_timeout(dut):
    tb = Abp_Receiver_Transmitter_Testbench(dut)
    dut.alternating_bit.value = 0
    await tb.reset()

    # Wait for 3 consecutive ACKs, all should be the same with alternating_bit=0
    for i in range(3):
        ack_frame_task = cocotb.start_soon(tb.sink.recv())
        timeout_task = Timer(100, units="us")
        result_frame = await First(ack_frame_task.join(), timeout_task)
        if result_frame is timeout_task:
            raise TestFailure(f"Test ended due to timeout on ACK {i}")
        
        
        expected_frame = AxiStreamFrame(tdata=b'\x00'*64)
        assert result_frame.tdata == expected_frame.tdata


@cocotb.test()
async def test_abp_rt_alternates_bits_noninterrupt(dut):
    tb = Abp_Receiver_Transmitter_Testbench(dut)
    await tb.reset()

    # Wait for 3 consecutive ACKs, all should be with alternating alternating_bits
    for i in range(4):
        dut.alternating_bit.value = i%2
        ack_frame_task = cocotb.start_soon(tb.sink.recv())
        timeout_task = Timer(100, units="us")
        result_frame = await First(ack_frame_task.join(), timeout_task)
        if result_frame is timeout_task:
            raise TestFailure(f"Test ended due to timeout on ACK {i}")
        
        expected_last_byte = b'\x00' if i%2==0 else b'\x01'
        expected_frame = AxiStreamFrame(tdata=b'\x00'*63 + expected_last_byte)
        assert result_frame.tdata == expected_frame.tdata


@cocotb.test()
async def test_abp_rt_alternates_bits_interrupted(dut):
    tb = Abp_Receiver_Transmitter_Testbench(dut)
    await tb.reset()

    async def drive_alternating_bit(signal, clk):
        while True:
            await Timer(1500, units='ns')
            await RisingEdge(clk)
            signal.value = not signal.value

    # chaos monkey -> flip alternating bit every 1.5us
    dut.alternating_bit.value = 0
    cocotb.start_soon(drive_alternating_bit(dut.alternating_bit, dut.aclk))

    # Wait for 10 consecutive ACK packets, all should be with associated alternating bit
    for i in range(10):
        expected_alternating_bit = dut.alternating_bit.value
        ack_frame_task = cocotb.start_soon(tb.sink.recv())
        timeout_task = Timer(100, units="us")
        result_frame = await First(ack_frame_task.join(), timeout_task)
        if result_frame is timeout_task:
            raise TestFailure(f"Test ended due to timeout on ACK {i}")
        
        expected_last_byte = b'\x00' if expected_alternating_bit==0 else b'\x01'
        expected_frame = AxiStreamFrame(tdata=b'\x00'*63 + expected_last_byte)
        assert result_frame.tdata == expected_frame.tdata

