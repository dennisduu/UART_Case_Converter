`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire rst_n,
    input wire baud_tick,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_out,
    output reg tx_ready
);
    // Internal signals
    reg [3:0] bit_idx;
    reg [9:0] shift_reg;
    reg tx_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out <= 1'b1;
            tx_ready <= 1;
            bit_idx <= 0;
            shift_reg <= 10'b1111111111;
            tx_active <= 0;
        end else begin
            if (tx_start && !tx_active) begin
                // Load data into shift register and start transmission
                shift_reg <= {1'b1, tx_data, 1'b0}; // STOP bit, DATA bits, START bit
                tx_active <= 1;
                bit_idx <= 0;
                tx_ready <= 0;
            end else if (tx_active && baud_tick) begin
                // Transmit bits on each baud tick
                tx_out <= shift_reg[0];
                shift_reg <= shift_reg >> 1;
                bit_idx <= bit_idx + 1;
                if (bit_idx == 9) begin
                    // Transmission complete
                    tx_active <= 0;
                    tx_ready <= 1;
                    tx_out <= 1'b1; // Set TX back to idle state (high)
                end
            end
        end
    end
endmodule
