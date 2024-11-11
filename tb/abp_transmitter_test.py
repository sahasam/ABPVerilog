import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

class ABPTransmitterTB:
    def __init__(self, dut):
        self.dut = dut
        self.axi_data_width = int(dut.DATA_WIDTH.value)
        self.value_size = int(dut.VALUE_SIZE.value)
        self.packet_size = int(dut.PACKET_SIZE.value)
        self.timeout_cycles = int(dut.TIMEOUT_CYCLES.value)

    async def reset(self):
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        await RisingEdge(self.dut.aclk)

    async def send_rx_packet(self, value, bit):
        self.dut.s_axis_tvalid.value = 1
        self.dut.s_axis_tdata.value = value & ((1 << self.axi_data_width) - 1)
        self.dut.s_axis_tlast.value = bit
        await RisingEdge(self.dut.aclk)
        while not self.dut.s_axis_tready.value:
            await RisingEdge(self.dut.aclk)
        self.dut.s_axis_tvalid.value = 0

    async def receive_tx_packet(self):
        while not self.dut.m_axis_tvalid.value:
            await RisingEdge(self.dut.aclk)
        value = 0
        for _ in range(self.value_size):
            value = (value << self.axi_data_width) | self.dut.m_axis_tdata.value
            await RisingEdge(self.dut.aclk)
        bit = self.dut.m_axis_tlast.value
        return value, bit

@cocotb.test(timeout_time=15000, timeout_unit="ns")
async def test_normal_operation(dut):
    tb = ABPTransmitterTB(dut)
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    # Check initial transmission
    value, bit = await tb.receive_tx_packet()
    assert value == 0 and bit == 1, f"Initial packet incorrect: value={value}, bit={bit}"

    # Send a response and check next transmission
    await tb.send_rx_packet(42, 1)
    value, bit = await tb.receive_tx_packet()
    assert value == 43 and bit == 0, f"Response packet incorrect: value={value}, bit={bit}"

    # Continue for a few more exchanges
    for i in range(3):
        await tb.send_rx_packet(value, bit)
        value, bit = await tb.receive_tx_packet()
        assert value == (value + 1) % (1 << (tb.value_size * 8)), f"Packet {i} incorrect: value={value}"
        assert bit == (i % 2 == 0), f"Packet {i} incorrect bit: {bit}"

@cocotb.test(timeout_time=10000, timeout_unit="ns")
async def test_normal_operation(dut):
    tb = ABPTransmitterTB(dut)
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    # Check initial transmission
    value, bit = await tb.receive_tx_packet()
    assert value == 0 and bit == 1, f"Initial packet incorrect: value={value}, bit={bit}"

    # Send a response and check next transmission
    await tb.send_rx_packet(42, 1)
    value, bit = await tb.receive_tx_packet()
    assert value == 43 and bit == 0, f"Response packet incorrect: value={value}, bit={bit}"

    # Continue for a few more exchanges
    for i in range(3):
        await tb.send_rx_packet(value, bit)
        value, bit = await tb.receive_tx_packet()
        assert value == (value + 1) % (1 << (tb.value_size * 8)), f"Packet {i} incorrect: value={value}"
        assert bit == (i % 2 == 0), f"Packet {i} incorrect bit: {bit}"

@cocotb.test(timeout_time=100, timeout_unit="us")
async def test_timeout_retransmission(dut):
    tb = ABPTransmitterTB(dut)
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    # Receive initial transmission
    initial_value, initial_bit = await tb.receive_tx_packet()

    # Wait for timeout
    await Timer(tb.timeout_cycles * 10, units="ns")

    # Check retransmission
    retrans_value, retrans_bit = await tb.receive_tx_packet()
    assert retrans_value == initial_value and retrans_bit == initial_bit, \
        f"Retransmission doesn't match: initial=({initial_value}, {initial_bit}), retrans=({retrans_value}, {retrans_bit})"

@cocotb.test(timeout_time=10000, timeout_unit="ns")
async def test_multiple_timeouts(dut):
    tb = ABPTransmitterTB(dut)
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    # Receive initial transmission
    initial_value, initial_bit = await tb.receive_tx_packet()

    # Check multiple retransmissions
    for _ in range(3):
        await Timer(tb.timeout_cycles * 10, units="ns")
        retrans_value, retrans_bit = await tb.receive_tx_packet()
        assert retrans_value == initial_value and retrans_bit == initial_bit, \
            f"Retransmission doesn't match: initial=({initial_value}, {initial_bit}), retrans=({retrans_value}, {retrans_bit})"

@cocotb.test(timeout_time=10000, timeout_unit="ns")
async def test_late_response(dut):
    tb = ABPTransmitterTB(dut)
    clock = Clock(dut.aclk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    # Receive initial transmission
    initial_value, initial_bit = await tb.receive_tx_packet()

    # Wait for almost a timeout
    await Timer((tb.timeout_cycles - 10) * 10, units="ns")

    # Send a late response
    await tb.send_rx_packet(42, initial_bit)

    # Check next transmission
    value, bit = await tb.receive_tx_packet()
    assert value == 43 and bit == (not initial_bit), f"Late response handling incorrect: value={value}, bit={bit}"
