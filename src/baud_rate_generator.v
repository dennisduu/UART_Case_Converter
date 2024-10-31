`timescale 1ns / 1ps

module baud_rate_generator #(
    parameter CLK_FREQ = 50000000,   // System clock frequency
    parameter BAUD_RATE = 9600       // Desired baud rate
)(
    input wire clk,                  // System clock
    input wire rst_n,                // Active low reset
    output reg baud_tick             // Baud rate tick
);
    localparam integer BAUD_DIV = CLK_FREQ / BAUD_RATE;
    reg [$clog2(BAUD_DIV)-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            baud_tick <= 0;
        end else if (counter == BAUD_DIV - 1) begin
            counter <= 0;
            baud_tick <= 1;
        end else begin
            counter <= counter + 1;
            baud_tick <= 0;
        end
    end
endmodule
