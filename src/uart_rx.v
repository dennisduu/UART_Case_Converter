module uart_rx (
    output reg [7:0] o_data,
    output reg o_valid,
    input wire i_in,
    input wire baud_tick,  // Use baud tick from baud generator
    input wire i_rst,
    input wire i_clk
);
    reg [3:0] state = 0;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= 0;
            o_valid <= 0;
        end else if (baud_tick) begin
            case (state)
                0: begin
                    o_valid <= 0;
                    if (i_in == 0) begin  // Start bit detected
                        state <= 1;
                    end
                end
                1: o_data[0] <= i_in; state <= 2;
                2: o_data[1] <= i_in; state <= 3;
                3: o_data[2] <= i_in; state <= 4;
                4: o_data[3] <= i_in; state <= 5;
                5: o_data[4] <= i_in; state <= 6;
                6: o_data[5] <= i_in; state <= 7;
                7: o_data[6] <= i_in; state <= 8;
                8: o_data[7] <= i_in; state <= 9;
                9: begin
                    o_valid <= 1;  // Data is valid
                    state <= 0;
                end
            endcase
        end
    end
endmodule
