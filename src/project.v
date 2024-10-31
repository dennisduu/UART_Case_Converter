/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0


`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule

 */


/*
 * Copyright (c) 2024 Weihua Xiao
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_uart_fifo (
    input  wire [7:0] ui_in,    // Dedicated inputs (data to transmit)
    output wire [7:0] uo_out,   // Dedicated outputs (TX and RX output)
    input  wire [7:0] uio_in,   // IOs: Input path (RX input)
    output wire [7:0] uio_out,  // IOs: Output path (unused in this case)
    output wire [7:0] uio_oe,   // IOs: Enable path (unused, all 0)
    input  wire       ena,      // Always 1 when the design is powered
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active low reset
);

    // Parameters
    parameter CLK_FREQ = 50000000;  // System clock frequency (50 MHz)
    parameter BAUD_RATE = 9600;     // UART baud rate

    // Internal wires and registers
    wire baud_tick;
    wire tx_ready;
    wire rx_valid;
    wire [7:0] rx_data;
    reg [7:0] tx_data; // Defined as a register for procedural assignments
    reg tx_start;

    // FIFO signals
    wire [7:0] tx_fifo_data_out;
    wire [7:0] rx_fifo_data_out;
    wire tx_fifo_full, tx_fifo_empty;
    wire rx_fifo_full, rx_fifo_empty;
    reg tx_fifo_rd_en;
    reg rx_fifo_wr_en;

    // Data input from external source (for TX FIFO)
    wire [7:0] data_in = ui_in;

    // UART RX and TX lines
    wire rx = uio_in[0];      // RX input from uio_in[0]
    wire tx;                  // TX output

    // Assign TX output to uo_out[0]
    assign uo_out[0] = tx;

    // Unused outputs
    assign uo_out[7:1] = 7'b0;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Instantiate baud rate generator
    baud_rate_generator #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // Instantiate UART receiver
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .rx(rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // Instantiate UART transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_out(tx),
        .tx_ready(tx_ready)
    );
    wire [7:0] fifo_tx_data;
    reg [7:0] tx_data;
    // Instantiate TX FIFO
    fifo #(
        .DEPTH(16),
        .WIDTH(8)
    ) tx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(rx_fifo_wr_en),
        .rd_en(tx_fifo_rd_en),
        .din(rx_fifo_data_out),
        .dout(fifo_tx_data), // Connect to fifo_tx_data instead of tx_data
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );


    // Character conversion and FIFO control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_start <= 0;
            tx_fifo_rd_en <= 0;
            rx_fifo_wr_en <= 0;
        end else begin
            // RX FIFO to TX FIFO with character conversion
            if (!rx_fifo_empty && !tx_fifo_full) begin
                rx_fifo_wr_en <= 1;
            end else begin
                rx_fifo_wr_en <= 0;
            end

            // Read from TX FIFO and start UART transmission
            if (!tx_fifo_empty && tx_ready) begin
                tx_fifo_rd_en <= 1;
                tx_start <= 1;
            end else begin
                tx_fifo_rd_en <= 0;
                tx_start <= 0;
            end
        end
    end

// Character conversion logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_data <= 8'b0; // Reset tx_data
    end else if (rx_fifo_wr_en) begin
        // Check if the character is a lowercase letter
        if (fifo_tx_data >= 8'h61 && fifo_tx_data <= 8'h7A) begin
            // Convert to uppercase by subtracting 32
            tx_data <= fifo_tx_data - 8'd32;
        end else begin
            // Keep the character as is
            tx_data <= fifo_tx_data;
        end
    end
end
endmodule

