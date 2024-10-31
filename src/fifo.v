`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 16,      // FIFO depth
    parameter WIDTH = 8        // Data width
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,               // Write enable
    input wire rd_en,               // Read enable
    input wire [WIDTH-1:0] din,     // Data input
    output reg [WIDTH-1:0] dout,    // Data output
    output reg full,                // FIFO full flag
    output reg empty                // FIFO empty flag
);
    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];  // FIFO memory array
    reg [$clog2(DEPTH)-1:0] rd_ptr;        // Read pointer
    reg [$clog2(DEPTH)-1:0] wr_ptr;        // Write pointer
    reg [$clog2(DEPTH):0] fifo_cnt;        // Counter for FIFO elements

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_cnt <= 0;
            full <= 0;
            empty <= 1;
            dout <= 0;
        end else begin
            // Write operation
            if (wr_en && !full) begin
                fifo_mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                fifo_cnt <= fifo_cnt + 1;
            end
            // Read operation
            if (rd_en && !empty) begin
                dout <= fifo_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                fifo_cnt <= fifo_cnt - 1;
            end
            // Update full and empty flags
            full <= (fifo_cnt == DEPTH);
            empty <= (fifo_cnt == 0);
        end
    end
endmodule
