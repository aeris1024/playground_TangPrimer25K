module top #(
    parameter integer HEARTBEAT_HALF_CYCLES = 50_000_000
) (
    input  wire clk,
    output wire led_ready,
    output wire led_done
);
    localparam integer COUNTER_WIDTH =
        (HEARTBEAT_HALF_CYCLES <= 1) ? 1 : $clog2(HEARTBEAT_HALF_CYCLES);

    wire pll_clock;
    wire pll_locked;
    reg [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}};
    reg heartbeat = 1'b0;

    pll_50_to_100 clock_generator (
        .clk_in(clk),
        .clk_out(pll_clock),
        .locked(pll_locked)
    );

    always @(posedge pll_clock) begin
        if (!pll_locked) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            heartbeat <= 1'b0;
        end else if (counter == HEARTBEAT_HALF_CYCLES - 1) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            heartbeat <= ~heartbeat;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    assign led_done = pll_locked;
    assign led_ready = pll_locked & heartbeat;
endmodule
