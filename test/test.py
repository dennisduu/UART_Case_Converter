import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import random

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut._log.info("Test project behavior")

    # Set the initial input values you want to test (original test)
    dut.a.value = 13
    dut.b.value = 10

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 10)

    # Log and assert the expected output for the initial values
    dut._log.info(f"value of outputs are: {dut.sum.value} and {dut.carry_out.value}.")
    assert dut.sum.value == 7 and dut.carry_out.value == 1 

    # Add random 1000 test cases
    for i in range(1000):
        # Generate random values for a and b within the 4-bit range (0 to 15)
        a = random.randint(0, 15)
        b = random.randint(0, 15)

        # Set the random input values
        dut.a.value = a
        dut.b.value = b

        # Wait for 10 clock cycles to settle
        await ClockCycles(dut.clk, 10)

        # Calculate the expected sum and carry_out
        expected_sum = (a + b) & 0xF  # Lower 4 bits for sum
        expected_carry_out = (a + b) >> 4  # Carry out

        # Log the values for debugging
        dut._log.info(f"Test {i + 1}: a={a}, b={b}, sum={dut.sum.value}, carry_out={dut.carry_out.value}")

        # Assert to check if the output matches the expected values
        assert dut.sum.value == expected_sum, f"Test {i + 1} failed for a={a}, b={b}: expected sum={expected_sum}, got {dut.sum.value}"
        assert dut.carry_out.value == expected_carry_out, f"Test {i + 1} failed for a={a}, b={b}: expected carry_out={expected_carry_out}, got {dut.carry_out.value}"

    dut._log.info("All tests passed.")
