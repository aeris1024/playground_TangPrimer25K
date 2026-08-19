module top #(
    parameter integer HALF_PERIOD_CYCLES = 13_500_000
) (
    input  wire clk,
    output reg  led = 1'b0
);
    localparam integer COUNTER_WIDTH =
        (HALF_PERIOD_CYCLES <= 1) ? 1 : $clog2(HALF_PERIOD_CYCLES);

    reg [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}};

    always @(posedge clk) begin
        if (counter == HALF_PERIOD_CYCLES - 1) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            led <= ~led;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule
