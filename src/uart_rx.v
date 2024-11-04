module uart_rx
#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD = 9600
)
(
    output reg [7:0] o_data,
    output reg o_valid,
    input wire i_in,
    input wire i_rst,
    input wire i_clk
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;
    reg [3:0] state = 0;  // State machine
    reg [$clog2(CLKS_PER_BIT):0] counter = 0;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= 0;
            o_valid <= 0;
        end else begin
            case (state)
                0: begin
                    o_valid <= 0;
                    if (i_in == 0) begin  // Start bit detected
                        state <= 1;
                        counter <= CLKS_PER_BIT / 2;
                    end
                end
                1: begin  // Wait for middle of start bit
                    if (counter == 0) begin
                        counter <= CLKS_PER_BIT - 1;
                        state <= 2;
                    end else begin
                        counter <= counter - 1;
                    end
                end
                2,3,4,5,6,7,8,9: begin  // Receive data bits
                    if (counter == 0) begin
                        o_data[state - 2] <= i_in;
                        counter <= CLKS_PER_BIT - 1;
                        state <= state + 1;
                    end else begin
                        counter <= counter - 1;
                    end
                end
                10: begin  // Stop bit
                    if (counter == 0) begin
                        o_valid <= 1;
                        state <= 0;
                    end else begin
                        counter <= counter - 1;
                    end
                end
                default: state <= 0;
            endcase
        end
    end

endmodule
