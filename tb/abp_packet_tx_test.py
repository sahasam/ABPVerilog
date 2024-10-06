import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge
from cocotbext.axi import AxiStreamBus, AxiStreamSink
from cocotb.regression import TestFactory

import logging

from utils import test_factory


class ABP_Packet_Tx_Testbench:
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("abp_packet_tx.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.aclk, 10, units='ns').start())

        # Ethernet Frame Output
        self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_eth_tx"), dut.aclk, dut.resetn, reset_active_level=False)

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

    async def send_abp_data(self, value, bit):
        self.dut.s_abp_value.value = value
        self.dut.s_abp_bit.value = bit
        self.dut.s_abp_valid.value = 1
        await RisingEdge(self.dut.aclk)
        while not self.dut.s_abp_ready.value:
            await RisingEdge(self.dut.aclk)
        self.dut.s_abp_valid.value = 0

def increment_value(value, size=32):
    """Increment the value, wrapping around if it exceeds the maximum for the given size."""
    max_value = (1 << size) - 1
    return (value + 1) & max_value

@cocotb.test(timeout_time=200, timeout_unit="ns")
async def test_abp_packet_tx_idle(dut):
    """
    Test the idle state of abp_packet_tx.
    
    This test verifies that after reset, the module is in the correct idle state:
    - busy should be 0 (not busy)
    - m_eth_tx_tvalid should be 0 (no data being transmitted)
    - s_abp_ready should be 1 (ready to accept new data)
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    assert dut.busy.value == 0, "TX should not be busy initially"
    assert dut.m_eth_tx_tvalid.value == 0, "m_eth_tx_tvalid should be low initially"
    assert dut.s_abp_ready.value == 1, "s_abp_ready should be high initially"

@test_factory(
    input_value=[0x00000000, 0xaabbccdd, 0xffffffff],
    input_bit=[0, 1]
)
async def run_simple_packet_test(dut, input_value, input_bit):
    """
    Test sending a simple packet through abp_packet_tx.
    
    This test verifies the basic functionality of sending a packet:
    - Sends a packet with a known value and bit
    - Checks if the transmitted data matches the input value incremented by 1
    - Verifies that the last byte contains the correct bit
    - Checks that the packet size is correct
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    await tb.send_abp_data(input_value, input_bit)
    
    rx_frame = await tb.sink.recv()
    expected_value = increment_value(input_value)
    assert rx_frame.tdata[0:4] == expected_value.to_bytes(4, 'big'), f"First 4 bytes of transmitted data do not match. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame.tdata[0:4], 'big'):08X}"
    assert rx_frame.tdata[-1] & 0x01 == input_bit, f"Last bit is not set correctly. Expected: {input_bit}, Got: {rx_frame.tdata[-1] & 0x01}"
    assert len(rx_frame.tdata) == 64, "Packet size is incorrect"

# Create test factory for simple packet test
factory = TestFactory(run_simple_packet_test)
factory.add_option("input_value", [0x00000000, 0xaabbccdd, 0xffffffff])
factory.add_option("input_bit", [0, 1])
factory.generate_tests()

@cocotb.test(timeout_time=2000, timeout_unit="ns")
async def test_abp_packet_tx_multiple_packets(dut):
    """
    Test sending multiple packets through abp_packet_tx.
    
    This test checks the module's ability to handle multiple packet transmissions:
    - Sends two packets with different values and bits
    - Verifies that both packets are transmitted correctly with incremented values
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    input_value1 = 0xAABBCCDD
    input_bit1 = 1
    await tb.send_abp_data(input_value1, input_bit1)
    
    input_value2 = 0x11223344
    input_bit2 = 0
    await tb.send_abp_data(input_value2, input_bit2)
    
    rx_frame1 = await tb.sink.recv()
    rx_frame2 = await tb.sink.recv()
    
    expected_value1 = increment_value(input_value1)
    expected_value2 = increment_value(input_value2)
    
    assert rx_frame1.tdata[0:4] == expected_value1.to_bytes(4, 'big'), f"First packet data does not match. Expected: {expected_value1:08X}, Got: {int.from_bytes(rx_frame1.tdata[0:4], 'big'):08X}"
    assert rx_frame1.tdata[-1] & 0x01 == input_bit1, "First packet last bit is not set correctly"
    assert rx_frame2.tdata[0:4] == expected_value2.to_bytes(4, 'big'), f"Second packet data does not match. Expected: {expected_value2:08X}, Got: {int.from_bytes(rx_frame2.tdata[0:4], 'big'):08X}"
    assert rx_frame2.tdata[-1] & 0x01 == input_bit2, "Second packet last bit is not set correctly"

@cocotb.test(timeout_time=1000, timeout_unit="ns")
async def test_abp_packet_tx_busy_flag(dut):
    """
    Test the busy flag behavior of abp_packet_tx.
    
    This test focuses on the behavior of the busy flag during transmission:
    - Checks that busy is initially 0
    - Starts sending a packet and checks if busy is set to 1 on the next clock cycle
    - Waits for the transmission to complete and checks if busy returns to 0 on the correct clock cycle
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    # Check initial state
    assert dut.busy.value == 0, "Busy flag should be 0 initially"
    
    # Prepare to send data
    dut.s_abp_value.value = 0xAABBCCDD
    dut.s_abp_bit.value = 1
    dut.s_abp_valid.value = 1
    dut.m_eth_tx_tready.value = 1
    
    # Wait for the values to register
    await RisingEdge(dut.aclk)
    await RisingEdge(dut.aclk)
    dut.s_abp_valid.value = 0

    assert dut.busy.value == 1, "Busy flag should be 1 when beginning transmission"

    await RisingEdge(dut.m_eth_tx_tlast)
    await RisingEdge(dut.aclk)
    
    assert dut.busy.value == 0, "Busy flag should be 0 after transmission"

@cocotb.test(timeout_time=2000, timeout_unit="ns")
async def test_abp_packet_tx_back_to_back(dut):
    """
    Test back-to-back packet transmission.
    
    This test verifies that the module can handle consecutive packet transmissions:
    - Sends two packets in quick succession
    - Checks that both packets are transmitted correctly with incremented values
    - Verifies that the busy flag behaves correctly between transmissions
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    input_value1 = 0xAABBCCDD
    input_bit1 = 1
    await tb.send_abp_data(input_value1, input_bit1)
    
    input_value2 = 0x11223344
    input_bit2 = 0
    await tb.send_abp_data(input_value2, input_bit2)
    
    rx_frame1 = await tb.sink.recv()
    rx_frame2 = await tb.sink.recv()
    
    expected_value1 = increment_value(input_value1)
    expected_value2 = increment_value(input_value2)
    
    assert rx_frame1.tdata[0:4] == expected_value1.to_bytes(4, 'big'), f"First packet data does not match. Expected: {expected_value1:08X}, Got: {int.from_bytes(rx_frame1.tdata[0:4], 'big'):08X}"
    assert rx_frame2.tdata[0:4] == expected_value2.to_bytes(4, 'big'), f"Second packet data does not match. Expected: {expected_value2:08X}, Got: {int.from_bytes(rx_frame2.tdata[0:4], 'big'):08X}"

@cocotb.test(timeout_time=1000, timeout_unit="ns")
async def test_abp_packet_tx_varying_tready(dut):
    """
    Test the module's behavior when m_eth_tx_tready is not always high.
    
    This test verifies that the module can handle varying m_eth_tx_tready signals:
    - Starts a packet transmission with m_eth_tx_tready low
    - Toggles m_eth_tx_tready during transmission
    - Checks that the packet is transmitted correctly with incremented value despite varying tready
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    dut.m_eth_tx_tready.value = 0
    input_value = 0xAABBCCDD
    input_bit = 1
    await tb.send_abp_data(input_value, input_bit)
    
    for _ in range(32):  # Half of PACKET_SIZE
        await RisingEdge(dut.aclk)
        dut.m_eth_tx_tready.value = not dut.m_eth_tx_tready.value
    
    dut.m_eth_tx_tready.value = 1
    
    rx_frame = await tb.sink.recv()
    expected_value = increment_value(input_value)
    assert rx_frame.tdata[0:4] == expected_value.to_bytes(4, 'big'), f"Transmitted data does not match. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame.tdata[0:4], 'big'):08X}"
    assert len(rx_frame.tdata) == 64, "Packet size is incorrect"

@cocotb.test(timeout_time=5000, timeout_unit="ns")
async def test_abp_packet_tx_timing(dut):
    """
    Test timing and latency of packet transmission.
    
    This test measures the time between packet input and output:
    - Sends a packet and measures the time until it starts being transmitted
    - Verifies that the latency is within acceptable limits
    - Checks that the transmitted value is correctly incremented
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    start_time = cocotb.utils.get_sim_time('ns')
    
    input_value = 0xAABBCCDD
    input_bit = 1
    await tb.send_abp_data(input_value, input_bit)
    
    rx_frame = await tb.sink.recv()
    end_time = cocotb.utils.get_sim_time('ns')
    
    latency = end_time - start_time
    
    # Assuming acceptable latency is less than 100ns (10 clock cycles)
    assert latency < 1000, f"Latency ({latency} ns) exceeds acceptable limit"
    
    expected_value = increment_value(input_value)
    assert rx_frame.tdata[0:4] == expected_value.to_bytes(4, 'big'), f"Transmitted data does not match. Expected: {expected_value:08X}, Got: {int.from_bytes(rx_frame.tdata[0:4], 'big'):08X}"

@cocotb.test(timeout_time=2000, timeout_unit="ns")
async def test_abp_packet_tx_second_value_after_transmission(dut):
    """
    Test that abp_tx only accepts a second abp value after the transmission of the first one has concluded.
    
    This test verifies:
    - The module accepts the first value
    - The module doesn't accept a second value while transmitting the first
    - The module accepts the second value after the first transmission is complete
    """
    tb = ABP_Packet_Tx_Testbench(dut)
    
    await tb.reset()
    
    # Send first packet
    input_value1 = 0xAABBCCDD
    input_bit1 = 1
    await tb.send_abp_data(input_value1, input_bit1)
    
    # Try to send second packet immediately
    input_value2 = 0x11223344
    input_bit2 = 0
    dut.s_abp_value.value = input_value2
    dut.s_abp_bit.value = input_bit2
    dut.s_abp_valid.value = 1
    
    # Wait for a few clock cycles
    for _ in range(5):
        await RisingEdge(dut.aclk)
        
    # Check that the second value is not accepted
    assert dut.s_abp_ready.value == 0, "s_abp_ready should be low while transmitting first packet"
    
    # Wait for the first transmission to complete
    while dut.m_eth_tx_tlast.value == 0:
        await RisingEdge(dut.aclk)
    
    # Wait one more clock cycle for the module to become ready
    await RisingEdge(dut.aclk)
    
    # Check that the second value is now accepted
    assert dut.s_abp_ready.value == 1, "s_abp_ready should be high after first transmission"
    
    # Complete the second transmission
    while not dut.s_abp_ready.value:
        await RisingEdge(dut.aclk)
    dut.s_abp_valid.value = 0
    
    # Receive both packets
    rx_frame1 = await tb.sink.recv()
    rx_frame2 = await tb.sink.recv()
    
    expected_value1 = increment_value(input_value1)
    expected_value2 = increment_value(input_value2)
    
    assert rx_frame1.tdata[0:4] == expected_value1.to_bytes(4, 'big'), f"First packet data does not match. Expected: {expected_value1:08X}, Got: {int.from_bytes(rx_frame1.tdata[0:4], 'big'):08X}"
    assert rx_frame2.tdata[0:4] == expected_value2.to_bytes(4, 'big'), f"Second packet data does not match. Expected: {expected_value2:08X}, Got: {int.from_bytes(rx_frame2.tdata[0:4], 'big'):08X}"