module uart_tx #(
    parameter integer CLOCK_HZ = 50_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       start,
    input  wire [7:0] data,
    output wire       tx,
    output wire       busy
);
    localparam integer CYCLES_PER_BIT = (CLOCK_HZ + BAUD_RATE / 2) / BAUD_RATE;
    localparam integer COUNT_WIDTH =
        (CYCLES_PER_BIT <= 1) ? 1 : $clog2(CYCLES_PER_BIT);

    reg [COUNT_WIDTH-1:0] cycle_count = {COUNT_WIDTH{1'b0}};
    reg [3:0] bit_index = 4'd0;
    reg [9:0] frame = 10'h3ff;
    reg tx_reg = 1'b1;
    reg busy_reg = 1'b0;

    assign tx = tx_reg;
    assign busy = busy_reg;

    always @(posedge clk) begin
        if (!busy_reg) begin
            tx_reg <= 1'b1;
            if (start) begin
                frame <= {1'b1, data, 1'b0};
                tx_reg <= 1'b0;
                busy_reg <= 1'b1;
                bit_index <= 4'd0;
                cycle_count <= {COUNT_WIDTH{1'b0}};
            end
        end else if (cycle_count == CYCLES_PER_BIT - 1) begin
            cycle_count <= {COUNT_WIDTH{1'b0}};
            if (bit_index == 4'd9) begin
                busy_reg <= 1'b0;
                tx_reg <= 1'b1;
            end else begin
                bit_index <= bit_index + 1'b1;
                tx_reg <= frame[bit_index + 1'b1];
            end
        end else begin
            cycle_count <= cycle_count + 1'b1;
        end
    end
endmodule
