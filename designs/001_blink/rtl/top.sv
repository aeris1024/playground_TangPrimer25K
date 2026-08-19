module top #(
    parameter integer HALF_PERIOD_CYCLES = 25_000_000
) (
    input  wire clk,
    output wire led
);
    localparam integer COUNTER_WIDTH =
        (HALF_PERIOD_CYCLES <= 1) ? 1 : $clog2(HALF_PERIOD_CYCLES);

    reg [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}};
    reg led_state = 1'b0;

    assign led = led_state;

    always @(posedge clk) begin
        if (counter == HALF_PERIOD_CYCLES - 1) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            led_state <= ~led_state;
        end else begin
            counter <= counter + 1'b1;
        end
    end
endmodule
