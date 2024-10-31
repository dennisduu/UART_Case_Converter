`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire rst_n,
    input wire baud_tick,
    input wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);
    // Internal signals
    reg [3:0] bit_idx;
    reg [9:0] shift_reg;
    reg rx_active;
    reg [$clog2(BAUD_RATE)-1:0] baud_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            data_valid <= 0;
            rx_active <= 0;
            bit_idx <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            if (!rx_active && !rx) begin
                // Start bit detected
                rx_active <= 1;
                baud_counter <= 0;
                bit_idx <= 0;
                data_valid <= 0;
            end else if (rx_active) begin
                if (baud_tick) begin
                    baud_counter <= baud_counter + 1;
                    if (baud_counter == (BAUD_RATE / 2) - 1) begin
                        // Sample data bit
                        shift_reg <= {rx, shift_reg[9:1]};
                        if (bit_idx == 9) begin
                            // Stop bit received
                            data_out <= shift_reg[8:1];
                            data_valid <= 1;
                            rx_active <= 0;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end
            end else begin
                data_valid <= 0;
            end
        end
    end
endmodule
