<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This 4-bit kogge stone adder is to perform fast addition of 4-bit binary numbers. It could reach delay complexity in O(log n) which is faster than the 4bit ripple carry adder O(n). It computes the rounding bits in parallel by generate and propagate signals to reduce the latency of the addition operation. Firstly, the rounding signals for adjacent bits are computed, and then the rounding signals for multiple bits are further combined. Then, the sum of each bit is calculated using the XOR operation. The design completes the addition operation quickly and outputs the sum as well as the final rounding signal.

## How to test

1. Input Configuration: The 4-bit binary numbers to be added are provided via the lower and upper halves of the 8-bit input (ui_in). The lower 4 bits represent one operand (A), and the upper 4 bits represent the other operand (B).

2. Running the Design: To test the adder:
*Provide the input values via the ui_in port.
*Ensure the design is powered (ena is active), and the reset signal (rst_n) is inactive.
*Observe the output sum and carry-out values on uo_out. The lower 4 bits of uo_out will represent the 4-bit sum, and uo_out[4] will represent the carry-out.

3. Example Test:
Input A = 4'b0011 and B = 4'b0101 via ui_in = 8'b01010011.
The expected output would be the sum 4'b1000 with carry-out 0, so uo_out = 8'b00001000.

## External hardware

No external hardware is required for this project. 
