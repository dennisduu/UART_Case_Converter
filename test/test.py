import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ReadOnly
from cocotb.result import TestFailure

# UART parameters
CLK_FREQ = 50000000     # 50 MHz clock frequency
BAUD_RATE = 9600        # UART baud rate
CLK_PERIOD = 1e9 / CLK_FREQ   # Clock period in ns
BAUD_PERIOD = int(round(1e9 / BAUD_RATE))  # Units: nanoseconds
 # Baud period in ns

# UART Transmission Task (send data to DUT's RX input)
async def uart_tx(dut, data):
    """Simulate UART transmission to the DUT's RX input."""
    # Build the frame: start bit (0), data bits (LSB first), stop bit (1)
    frame = [0]  # Start bit
    for i in range(8):
        frame.append((data >> i) & 1)
    frame.append(1)  # Stop bit

    # Send the frame
    for bit in frame:
        dut.rx_serial <= bit
        await Timer(BAUD_PERIOD, units='ns')

    # Ensure the line stays idle after transmission
    dut.rx_serial <= 1
    await Timer(BAUD_PERIOD, units='ns')

# UART Reception Task (receive data from DUT's TX output)
async def uart_rx(dut):
    """Simulate UART reception from the DUT's TX output."""
    # Wait for start bit (logic low)
    await FallingEdge(dut.tx_serial)
    # Wait half a baud period to sample in the middle of the bit
    await Timer(BAUD_PERIOD / 2, units='ns')

    # Read data bits
    data = 0
    for i in range(8):
        await Timer(BAUD_PERIOD, units='ns')
        bit = dut.tx_serial.value.integer
        data |= (bit << i)

    # Wait for stop bit
    await Timer(BAUD_PERIOD, units='ns')
    stop_bit = dut.tx_serial.value.integer
    if stop_bit != 1:
        raise TestFailure("Stop bit not detected")

    return data

@cocotb.test()
async def uart_capitalizer_test(dut):
    """Test the UART capitalizer design."""
    # Generate clock
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD, units='ns').start())

    # Apply reset
    dut.rst_n <= 0
    dut.ena <= 1       # Enable the design
    dut.rx_serial <= 1 # Idle state for UART line
    await Timer(100 * CLK_PERIOD, units='ns')
    dut.rst_n <= 1
    await RisingEdge(dut.clk)

    # Test data: mix of lowercase, uppercase, numbers, and special characters
    test_string = 'abCdE1!zYmNoP9?u'
    test_data = [ord(c) for c in test_string]

    # Expected data after capitalization
    expected_data = []
    for c in test_data:
        if ord('a') <= c <= ord('z'):
            expected_data.append(c - ord('a') + ord('A'))
        else:
            expected_data.append(c)

    received_data = []

    # Start UART receiver coroutine
    async def uart_rx_task():
        while len(received_data) < len(expected_data):
            data = await uart_rx(dut)
            received_data.append(data)
            dut._log.info(f"Received char: {chr(data)} (0x{data:02X})")

    rx_task = cocotb.start_soon(uart_rx_task())

    # Send data to DUT
    for idx, c in enumerate(test_data):
        dut._log.info(f"Sending char: {chr(c)} (0x{c:02X})")
        await uart_tx(dut, c)
        # Wait a bit before sending the next character
        await Timer(BAUD_PERIOD * 2, units='ns')

    # Wait for all data to be received
    await rx_task

    # Verify the received data
    errors = 0
    for idx, data in enumerate(received_data):
        expected_char = expected_data[idx]
        if data != expected_char:
            dut._log.error(f"Mismatch at index {idx}: "
                           f"Received {chr(data)} (0x{data:02X}), "
                           f"Expected {chr(expected_char)} (0x{expected_char:02X})")
            errors += 1
        else:
            dut._log.info(f"Match at index {idx}: "
                          f"{chr(data)} (0x{data:02X})")

    if errors == 0:
        dut._log.info("All tests passed.")
    else:
        raise TestFailure(f"Test failed with {errors} errors.")
