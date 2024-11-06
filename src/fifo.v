module uart_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ALMOST_FULL = 12
) (
    // Read port
    input wire i_rd_en,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_valid,

    // Write port
    input wire i_wr_en,
    input wire [WIDTH-1:0] i_wr_data,

    // Status
    output wire o_empty,
    output wire o_full,
    output wire o_almostfull,

    input wire i_clk,
    input wire i_rst
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] rd_ptr = 0;
    reg [ADDR_WIDTH-1:0] wr_ptr = 0;
    reg [ADDR_WIDTH:0] count = 0;

    assign o_empty = (count == 0);
    assign o_full = (count == DEPTH);
    assign o_almostfull = (count >= ALMOST_FULL);

    // Write Operation
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            wr_ptr <= 0;
            count <= 0;
        end else begin
            if (i_wr_en && !o_full) begin
                mem[wr_ptr] <= i_wr_data;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
        end
    end
    
    // Read Operation
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rd_ptr <= 0;
            o_rd_valid <= 0;
        end else begin
            o_rd_valid <= 0;
            if (i_rd_en && !o_empty) begin
                o_rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
                o_rd_valid <= 1;
            end
        end
    end


endmodule
