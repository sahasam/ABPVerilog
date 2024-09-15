import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge 
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamFrame
import logging

class ABP_Packet_Rx_Testbench:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("abp_packet_rx.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 8, units='ns').start())

        # Ethernet Frame Input
        self.source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "eth_rx"), dut.aclk, dut.resetn, reset_active_level=False)

    async def reset(self):
        self.dut.resetn.setimmediatevalue(1)
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.resetn.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.resetn.value = 1
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)

def packet_generator(value:int, bit:int) -> bytes:
    # 4 bytes for value
    # 59 bytes of padding
    # 1 byte for alternating bit
    return value.to_bytes(4, byteorder='big') + b'\x00'*(59) + bit.to_bytes(1, byteorder='big')

"""
Test 1: Given correct ethernet frame, exposes correct values on output port
"""
@cocotb.test(timeout_time=15, timeout_unit='us')
async def test_abp_rr_correctly_updates_sender_value(dut):
    tb = ABP_Packet_Rx_Testbench(dut)
    VALUE = 0x0a0b0c0d
    await tb.reset()
    tb.dut.abp_tx_ready.value = 0

    packet_data = packet_generator(VALUE, 1)
    tb.log.info(f"sending packet length: {len(packet_data)}")
    frame = AxiStreamFrame(tdata=packet_data)
    await tb.source.send(frame)

    # wait for packet to finish sending
    while True:
        await RisingEdge(dut.aclk)
        if dut.abp_tx_valid.value == 1:
            break

    assert tb.dut.abp_tx_value.value == VALUE
    assert tb.dut.abp_tx_bit.value == 1
    assert tb.dut.abp_tx_valid.value == 1


    await tb.reset()

"""
Test 2: Given correct ethernet frame, can read abp value
"""
@cocotb.test(timeout_time=15, timeout_unit='us')
async def test_abp_rr_correctly_receives_abp_data(dut):
    tb = ABP_Packet_Rx_Testbench(dut)
    VALUE = 0x0a0b0c0d
    await tb.reset()
    tb.dut.abp_tx_ready.value = 0

    packet_data = packet_generator(VALUE, 1)
    tb.log.info(f"sending packet length: {len(packet_data)}")
    frame = AxiStreamFrame(tdata=packet_data)
    await tb.source.send(frame)
    
    # wait for packet to finish sending
    while True:
        await RisingEdge(dut.aclk)
        if dut.abp_tx_valid.value == 1:
            break

    assert tb.dut.abp_tx_value.value == VALUE
    assert tb.dut.abp_tx_bit.value == 1
    assert tb.dut.abp_tx_valid.value == 1

    # wait for ready signal to go low
    tb.dut.abp_tx_ready.value = 1
    await RisingEdge(tb.dut.aclk)
    await RisingEdge(tb.dut.aclk)
    assert tb.dut.abp_tx_valid.value == 0


"""
Test 3: Given multiple ethernet frames, can send multiple values;
"""
@cocotb.test(timeout_time=15, timeout_unit='us')
async def test_abp_rr_correctly_receives_chained_packets(dut):
    tb = ABP_Packet_Rx_Testbench(dut)
    await tb.reset()

    VALUE = 0x0a0b0c0d
    tb.dut.abp_tx_ready.value = 0

    packet_data = packet_generator(VALUE, 1)
    tb.log.info(f"sending packet length: {len(packet_data)}")
    frame = AxiStreamFrame(tdata=packet_data)
    await tb.source.send(frame)
    
    # wait for packet to finish sending
    while True:
        await RisingEdge(dut.aclk)
        if dut.abp_tx_valid.value == 1:
            break

    assert tb.dut.abp_tx_value.value == VALUE
    assert tb.dut.abp_tx_bit.value == 1
    assert tb.dut.abp_tx_valid.value == 1

    # wait for ready signal to go low
    tb.dut.abp_tx_ready.value = 1
    await RisingEdge(tb.dut.aclk)
    await RisingEdge(tb.dut.aclk)
    assert tb.dut.abp_tx_valid.value == 0

    VALUE2 = 0xaabbccdd
    tb.dut.abp_tx_ready.value = 0
    packet_data = packet_generator(VALUE2, 0)
    tb.log.info(f"sending packet length: {len(packet_data)}")
    frame = AxiStreamFrame(tdata=packet_data)
    await tb.source.send(frame)
    
    # wait for packet to finish sending
    while True:
        await RisingEdge(dut.aclk)
        if dut.abp_tx_valid.value == 1:
            break

    assert tb.dut.abp_tx_value.value == VALUE2
    assert tb.dut.abp_tx_bit.value == 0
    assert tb.dut.abp_tx_valid.value == 1

    # wait for ready signal to go low
    tb.dut.abp_tx_ready.value = 1
    await RisingEdge(tb.dut.aclk)
    await RisingEdge(tb.dut.aclk)
    assert tb.dut.abp_tx_valid.value == 0