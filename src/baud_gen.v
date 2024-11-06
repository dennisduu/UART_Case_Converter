module baud_generator (
    output reg baud_tick,
    input wire i_clk,
    input wire i_rst
);
    parameter CLK_FREQ = 50000000;
    parameter BAUD = 9600;
    localparam integer BAUD_DIVISOR = CLK_FREQ / BAUD;

    reg [$clog2(BAUD_DIVISOR)-1:0] counter = 0;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            counter <= 0;
            baud_tick <= 0;
        end else if (counter == BAUD_DIVISOR - 1) begin
            counter <= 0;
            baud_tick <= 1;
        end else begin
            counter <= counter + 1;
            baud_tick <= 0;
        end
    end
endmodule
