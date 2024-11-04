/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/

/*
`default_nettype none
`timescale 1ns / 1ps
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_example user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule

*/

`default_nettype none
`timescale 1ns / 1ps

/* This testbench instantiates the UART capitalizer module and provides
   convenient wires that can be driven/tested by the cocotb test script.
*/
module tb();

  // Dump the signals to a VCD file for waveform viewing with GTKWave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Declare inputs and outputs
  reg clk;
  reg rst_n;
  reg ena;
  reg rx_serial;         // UART RX input (to DUT)
  wire tx_serial;        // UART TX output (from DUT)
  wire [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_in;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Assignments for UART signals
  assign ui_in[0] = rx_serial;  // Connect RX serial input to ui_in[0]
  assign ui_in[7:1] = 7'b0;     // Other bits unused
  assign tx_serial = uo_out[0]; // Connect uo_out[0] to TX serial output

  // Unused IOs
  assign uio_in = 8'b0;
  assign uio_out = 8'b0;
  assign uio_oe = 8'b0;

  // Instantiate the UART capitalizer module
  tt_um_uart_fifo user_project (

    // Include power ports for the Gate Level test
`ifdef GL_TEST
    .VPWR(VPWR),
    .VGND(VGND),
`endif

    .ui_in  (ui_in),    // Dedicated inputs
    .uo_out (uo_out),   // Dedicated outputs
    .uio_in (uio_in),   // IOs: Input path
    .uio_out(uio_out),  // IOs: Output path
    .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
    .ena    (ena),      // Enable signal
    .clk    (clk),      // System clock
    .rst_n  (rst_n)     // Active low reset
  );

endmodule
