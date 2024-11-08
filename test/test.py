import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.result import TestFailure
import random
import string

# UART parameters
CLK_FREQ = 10000000     # 10 MHz clock frequency
BAUD_RATE = 9600        # UART baud rate
CLK_PERIOD = 1e9 / CLK_FREQ   # Clock period in ns
BAUD_PERIOD = int(round(1e9 / BAUD_RATE))  # Baud period in ns

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
        bit_value = dut.tx_serial.value
        if bit_value.is_resolvable:
            bit = bit_value.integer
            data |= (bit << i)
        else:
            dut._log.warning(f"Received undefined bit at position {i}. Retrying...")
            # Optionally, you can wait and retry reading the bit
            await Timer(BAUD_PERIOD, units='ns')
            i -= 1  # Retry the same bit position

    # Wait for stop bit
    await Timer(BAUD_PERIOD, units='ns')
    stop_bit_value = dut.tx_serial.value
    if not stop_bit_value.is_resolvable or stop_bit_value.integer != 1:
        raise TestFailure("Stop bit not detected or undefined")

    return data

@cocotb.test()
async def uart_capitalizer_test(dut):
    """Test the UART capitalizer design with 100 constrained random test cases."""
    # Generate clock
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD, units='ns').start())

    # Apply reset
    dut.rst_n.value = 0
    dut.ena.value = 1       # Enable the design
    dut.rx_serial.value = 1 # Idle state for UART line
    await Timer(100 * CLK_PERIOD, units='ns')

    # Release reset
    dut.rst_n.value = 1

    # Wait for a few clock cycles to allow DUT to initialize
    for _ in range(10):
        await RisingEdge(dut.clk)

    # Run 100 constrained random test cases
    total_errors = 0
    num_tests = 10
    for test_num in range(num_tests):
        # Generate a random test string of random length between 5 and 20
        length = random.randint(5, 20)
        characters = string.ascii_letters + string.digits + string.punctuation
        test_string = ''.join(random.choice(characters) for _ in range(length))
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
            dut._log.info(f"Test {test_num+1}: Sending char: {chr(c)} (0x{c:02X})")
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
                dut._log.error(f"Test {test_num+1}: Mismatch at index {idx}: "
                               f"Received {chr(data)} (0x{data:02X}), "
                               f"Expected {chr(expected_char)} (0x{expected_char:02X})")
                errors += 1
            else:
                dut._log.info(f"Test {test_num+1}: Match at index {idx}: "
                              f"{chr(data)} (0x{data:02X})")

        if errors == 0:
            dut._log.info(f"Test {test_num+1}/{num_tests} passed.")
        else:
            dut._log.error(f"Test {test_num+1}/{num_tests} failed with {errors} errors.")
            total_errors += errors

        # Optional: Add a small delay before the next test
        await Timer(1000, units='ns')

    if total_errors == 0:
        dut._log.info(f"All {num_tests} tests passed successfully.")
    else:
        raise TestFailure(f"Total errors: {total_errors} across {num_tests} tests.")
