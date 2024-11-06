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
                4'd0: begin
                    o_valid <= 0;
                    if (i_in == 0) begin  // Start bit detected
                        state <= 4'd1;
                    end
                end
                4'd1: begin
                    o_data[0] <= i_in;
                    state <= 4'd2;
                end
                4'd2: begin
                    o_data[1] <= i_in;
                    state <= 4'd3;
                end
                4'd3: begin
                    o_data[2] <= i_in;
                    state <= 4'd4;
                end
                4'd4: begin
                    o_data[3] <= i_in;
                    state <= 4'd5;
                end
                4'd5: begin
                    o_data[4] <= i_in;
                    state <= 4'd6;
                end
                4'd6: begin
                    o_data[5] <= i_in;
                    state <= 4'd7;
                end
                4'd7: begin
                    o_data[6] <= i_in;
                    state <= 4'd8;
                end
                4'd8: begin
                    o_data[7] <= i_in;
                    state <= 4'd9;
                end
                4'd9: begin
                    // Stop bit (optional checking can be added here)
                    state <= 4'd10;
                end
                4'd10: begin
                    o_valid <= 1;  // Data is valid
                    state <= 4'd0;
                end
                default: begin
                    state <= 4'd0;
                end
            endcase
        end
    end
endmodule
