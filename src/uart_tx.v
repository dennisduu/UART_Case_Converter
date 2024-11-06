module uart_tx
#(
    parameter CLK_FREQ = 12000000,
    parameter BAUD = 9600
)
(
    output wire o_ready,
    output reg o_out,
    input wire [7:0] i_data,
    input wire i_valid,
    input wire i_rst,
    input wire i_clk
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;
    reg [3:0] state = 0;  // State machine
    reg [$clog2(CLKS_PER_BIT):0] counter = 0;
    reg [7:0] data_reg = 0;

    assign o_ready = (state == 0);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= 0;
            o_out <= 1;
        end else begin
            case (state)
                0: begin
                    o_out <= 1;
                    if (i_valid) begin
                        data_reg <= i_data;
                        state <= 1;
                        counter <= CLKS_PER_BIT - 1;
                        o_out <= 0;  // Start bit
                    end
                end
                1,2,3,4,5,6,7,8: begin  // Transmit data bits
                    if (counter == 0) begin
                        o_out <= data_reg[state - 1];
                        counter <= CLKS_PER_BIT - 1;
                        state <= state + 1;
                    end else begin
                        counter <= counter - 1;
                    end
                end
                9: begin  // Stop bit
                    if (counter == 0) begin
                        o_out <= 1;
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