import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink
from cocotb.regression import TestFactory

import logging
import random

class ABP_Receiver_Testbench:
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("abp_receiver.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 10, units='ns').start())

        # AXI Stream interfaces
        self.source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.aclk, dut.aresetn, reset_active_level=False)
        self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.aclk, dut.aresetn, reset_active_level=False)

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

    async def send_packet(self, value, bit):
        packet = value.to_bytes(4, 'big')
        packet += bytes([0] * 59)  # Padding
        packet += bytes([bit])
        await self.source.send(packet)

    async def receive_packet(self):
        rx_frame = await self.sink.recv()
        return rx_frame.tdata

def increment_value(value, size=32):
    """Increment the value, wrapping around if it exceeds the maximum for the given size."""
    max_value = (1 << size) - 1
    return (value + 1) & max_value

@cocotb.test(timeout_time=200, timeout_unit="ns")
async def test_abp_receiver_idle(dut):
    """
    Test the idle state of abp_receiver.
    
    This test verifies that after reset, the module is in the correct idle state:
    - s_axis_tready should be 1 (ready to receive data)
    - m_axis_tvalid should be 0 (no data being transmitted)
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    assert dut.s_axis_tready.value == 1, "s_axis_tready should be high initially"
    assert dut.m_axis_tvalid.value == 0, "m_axis_tvalid should be low initially"

async def run_simple_packet_test(dut, input_value, input_bit):
    """
    Test sending a simple packet through abp_receiver.
    
    This test verifies the basic functionality of receiving and transmitting a packet:
    - Sends a packet with a known value and bit
    - Checks if the transmitted data matches the input value incremented by 1
    - Verifies that the last byte contains the correct bit
    - Checks that the packet size is correct
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    await tb.send_packet(input_value, input_bit)
    
    rx_frame = await tb.receive_packet()
    expected_value = increment_value(input_value)
    assert rx_frame[0:4] == expected_value.to_bytes(4, 'big'), f"First 4 bytes of transmitted data do not match. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame[0:4], 'little'):08X}"
    assert rx_frame[-1] & 0x01 == input_bit, f"Last bit is not set correctly. Expected: {input_bit}, Got: {rx_frame[-1] & 0x01}"
    assert len(rx_frame) == 64, "Packet size is incorrect"

@cocotb.test(timeout_time=2500, timeout_unit="ns")
async def test_abp_receiver_multiple_packets(dut):
    """
    Test sending multiple packets through abp_receiver.
    
    This test checks the module's ability to handle multiple packet transmissions:
    - Sends two packets with different values and bits
    - Verifies that both packets are received and transmitted correctly with incremented values
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    input_value1 = 0xAABBCCDD
    input_bit1 = 1
    await tb.send_packet(input_value1, input_bit1)
    
    input_value2 = 0x11223344
    input_bit2 = 0
    await tb.send_packet(input_value2, input_bit2)
    
    rx_frame1 = await tb.receive_packet()
    rx_frame2 = await tb.receive_packet()
    
    expected_value1 = increment_value(input_value1)
    expected_value2 = increment_value(input_value2)
    
    assert rx_frame1[0:4] == expected_value1.to_bytes(4, 'big'), f"First packet data does not match. Expected: {expected_value1:08X}, Got: {int.from_bytes(rx_frame1[0:4], 'little'):08X}"
    assert rx_frame1[-1] & 0x01 == input_bit1, "First packet last bit is not set correctly"
    assert rx_frame2[0:4] == expected_value2.to_bytes(4, 'big'), f"Second packet data does not match. Expected: {expected_value2:08X}, Got: {int.from_bytes(rx_frame2[0:4], 'little'):08X}"
    assert rx_frame2[-1] & 0x01 == input_bit2, "Second packet last bit is not set correctly"

@cocotb.test(timeout_time=2500, timeout_unit="ns")
async def test_abp_receiver_back_to_back(dut):
    """
    Test back-to-back packet transmission through abp_receiver.
    
    This test verifies that the module can handle consecutive packet transmissions:
    - Sends two packets in quick succession
    - Checks that both packets are received and transmitted correctly with incremented values
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    input_value1 = 0xAABBCCDD
    input_bit1 = 1
    await tb.send_packet(input_value1, input_bit1)
    
    input_value2 = 0x11223344
    input_bit2 = 0
    await tb.send_packet(input_value2, input_bit2)
    
    rx_frame1 = await tb.receive_packet()
    rx_frame2 = await tb.receive_packet()
    
    expected_value1 = increment_value(input_value1)
    expected_value2 = increment_value(input_value2)
    
    assert rx_frame1[0:4] == expected_value1.to_bytes(4, 'big'), f"First packet data does not match. Expected: {expected_value1:08X}, Got: {int.from_bytes(rx_frame1[0:4], 'little'):08X}"
    assert rx_frame2[0:4] == expected_value2.to_bytes(4, 'big'), f"Second packet data does not match. Expected: {expected_value2:08X}, Got: {int.from_bytes(rx_frame2[0:4], 'little'):08X}"

@cocotb.test(timeout_time=10000, timeout_unit="ns")
async def test_abp_receiver_intermittent_transmission(dut):
    """
    Test intermittent packet transmission through abp_receiver.
    
    This test verifies that the module can handle packets with varying delays between them:
    - Sends multiple packets with different delays between them
    - Checks that all packets are received and transmitted correctly with incremented values
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    for i in range(5):
        input_value = random.randint(0, 0xFFFFFFFF)
        input_bit = i % 2
        await tb.send_packet(input_value, input_bit)
        
        rx_frame = await tb.receive_packet()
        expected_value = increment_value(input_value)
        
        assert rx_frame[0:4] == expected_value.to_bytes(4, 'big'), f"Packet {i} data does not match. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame[0:4], 'little'):08X}"
        assert rx_frame[-1] & 0x01 == input_bit, f"Packet {i} last bit is not set correctly"
        
        # Random delay between packets
        await Timer(random.randint(10, 1000), units='ns')

@cocotb.test(timeout_time=2000, timeout_unit="ns")
async def test_abp_receiver_max_value_wrapping(dut):
    """
    Test maximum value wrapping in abp_receiver.
    
    This test verifies that the module correctly handles the case when the input value is at its maximum:
    - Sends a packet with the maximum 32-bit value
    - Checks that the transmitted packet contains the wrapped (incremented) value of 0
    """
    tb = ABP_Receiver_Testbench(dut)
    
    await tb.reset()
    
    max_value = 0xFFFFFFFF
    input_bit = 1
    await tb.send_packet(max_value, input_bit)
    
    rx_frame = await tb.receive_packet()
    expected_value = 0  # Wrapping from 0xFFFFFFFF to 0x00000000
    
    assert rx_frame[0:4] == expected_value.to_bytes(4, 'big'), f"Max value wrapping failed. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame[0:4], 'little'):08X}"
    assert rx_frame[-1] & 0x01 == input_bit, "Last bit is not set correctly for max value packet"

# Conditional TestFactory setup
if cocotb.SIM_NAME:
    factory = TestFactory(run_simple_packet_test)
    factory.add_option("input_value", [0x00000000, 0xaabbccdd, 0xffffffff])
    factory.add_option("input_bit", [0, 1])
    factory.generate_tests()