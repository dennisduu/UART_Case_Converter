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
            state <= 4'd0;
            o_out <= 1;
        end else if (baud_tick) begin
            case (state)
                4'd0: begin
                    o_out <= 1;
                    if (i_valid) begin
                        data_reg <= i_data;
                        o_out <= 0;  // Start bit
                        state <= 4'd1;
                    end
                end
                4'd1: begin
                    o_out <= data_reg[0];
                    state <= 4'd2;
                end
                4'd2: begin
                    o_out <= data_reg[1];
                    state <= 4'd3;
                end
                4'd3: begin
                    o_out <= data_reg[2];
                    state <= 4'd4;
                end
                4'd4: begin
                    o_out <= data_reg[3];
                    state <= 4'd5;
                end
                4'd5: begin
                    o_out <= data_reg[4];
                    state <= 4'd6;
                end
                4'd6: begin
                    o_out <= data_reg[5];
                    state <= 4'd7;
                end
                4'd7: begin
                    o_out <= data_reg[6];
                    state <= 4'd8;
                end
                4'd8: begin
                    o_out <= data_reg[7];
                    state <= 4'd9;
                end
                4'd9: begin
                    o_out <= 1;  // Stop bit
                    state <= 4'd0;
                end
                default: begin
                    state <= 4'd0;
                end
            endcase
        end
    end
endmodule
