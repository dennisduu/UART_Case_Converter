`default_nettype none


module tt_um_uart_fifo (
    input  wire [7:0] ui_in,    // Dedicated inputs (unused in this case)
    output wire [7:0] uo_out,   // Dedicated outputs (TX and RX output)
    input  wire [7:0] uio_in,   // IOs: Input path (RX input)
    output wire [7:0] uio_out,  // IOs: Output path (unused)
    output wire [7:0] uio_oe,   // IOs: Enable path (unused)
    input  wire       ena,      // Always 1 when the design is powered
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active low reset
);

    // Parameters
    parameter CLK_FREQ = 12000000;  // System clock frequency (50 MHz)
    parameter BAUD_RATE = 115200;     // UART baud rate

    // Internal signals
    wire rx = ui_in[0];   // UART RX input
    wire tx;              // UART TX output
    assign uo_out[0] = tx;
    assign uo_out[7:1] = 7'b0;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Wires for UART modules
    wire [7:0] urx_data;
    wire urx_valid;
    wire [7:0] utx_data;
    wire utx_valid;
    wire utx_ready;

    // FIFO signals
    wire fifo_empty, fifo_full;
    reg fifo_rd_en;
    reg fifo_wr_en;
    wire [7:0] fifo_dout;

    // Character conversion logic
    reg [7:0] processed_data;

    // Instantiate UART Receiver
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD_RATE)
    ) uart_rx_inst (
        .o_data(urx_data),
        .o_valid(urx_valid),
        .i_in(rx),
        .i_rst(~rst_n),
        .i_clk(clk)
    );

    // Instantiate UART Transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD_RATE)
    ) uart_tx_inst (
        .o_ready(utx_ready),
        .o_out(tx),
        .i_data(utx_data),
        .i_valid(utx_valid),
        .i_rst(~rst_n),
        .i_clk(clk)
    );

    // Instantiate FIFO
    uart_fifo #(
        .WIDTH(8),
        .DEPTH(16),
        .ALMOST_FULL(12)
    ) fifo_inst (
        .i_rd_en(fifo_rd_en),
        .o_rd_data(fifo_dout),
        .o_rd_valid(utx_valid),
        .i_wr_en(fifo_wr_en),
        .i_wr_data(processed_data),
        .o_empty(fifo_empty),
        .o_full(fifo_full),
        .o_almostfull(),
        .i_clk(clk),
        .i_rst(~rst_n)
    );

    // Character conversion and FIFO control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_en <= 0;
            fifo_rd_en <= 0;
        end else begin
            fifo_wr_en <= 0;
            fifo_rd_en <= 0;

            // When a valid byte is received
            if (urx_valid && !fifo_full) begin
                // Character conversion
                if (urx_data >= "a" && urx_data <= "z") begin
                    processed_data <= urx_data - 8'd32;  // Convert to uppercase
                end else begin
                    processed_data <= urx_data;
                end
                fifo_wr_en <= 1;  // Write to FIFO
            end

            // When transmitter is ready and FIFO is not empty
            if (utx_ready && !fifo_empty) begin
                fifo_rd_en <= 1;  // Read from FIFO
            end
        end
    end

    // Assign FIFO output to UART transmitter data input
    assign utx_data = fifo_dout;

endmodule