module uart_tx (
    output wire o_ready,
    output reg o_out,
    input wire [7:0] i_data,
    input wire i_valid,
    input wire baud_tick,  // Use baud tick from baud generator
    input wire i_rst,
    input wire i_clk
);
    reg [3:0] state = 0;
    reg [7:0] data_reg = 0;

    assign o_ready = (state == 0);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= 0;
            o_out <= 1;
        end else if (baud_tick) begin
            case (state)
                0: begin
                    o_out <= 1;
                    if (i_valid) begin
                        data_reg <= i_data;
                        state <= 1;
                        o_out <= 0;  // Start bit
                    end
                end
                1: o_out <= data_reg[0]; state <= 2;
                2: o_out <= data_reg[1]; state <= 3;
                3: o_out <= data_reg[2]; state <= 4;
                4: o_out <= data_reg[3]; state <= 5;
                5: o_out <= data_reg[4]; state <= 6;
                6: o_out <= data_reg[5]; state <= 7;
                7: o_out <= data_reg[6]; state <= 8;
                8: o_out <= data_reg[7]; state <= 9;
                9: begin
                    o_out <= 1;  // Stop bit
                    state <= 0;
                end
            endcase
        end
    end
endmodule
