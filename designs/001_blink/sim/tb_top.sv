`timescale 1ns/1ps

module tb_top;
    localparam integer TEST_HALF_PERIOD = 4;

    reg clk = 1'b0;
    wire led;

    integer cycles_since_toggle = 0;
    integer toggle_count = 0;
    reg previous_led;

    top #(
        .HALF_PERIOD_CYCLES(TEST_HALF_PERIOD)
    ) dut (
        .clk(clk),
        .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        previous_led = led;

        repeat (TEST_HALF_PERIOD * 5) begin
            @(posedge clk);
            #1;
            cycles_since_toggle = cycles_since_toggle + 1;

            if (led !== previous_led) begin
                if (cycles_since_toggle != TEST_HALF_PERIOD) begin
                    $display("TEST 001_blink ... FAIL (toggle after %0d cycles)",
                             cycles_since_toggle);
                    $fatal(1);
                end
                previous_led = led;
                cycles_since_toggle = 0;
                toggle_count = toggle_count + 1;
            end
        end

        if (toggle_count < 4) begin
            $display("TEST 001_blink ... FAIL (only %0d toggles)", toggle_count);
            $fatal(1);
        end

        $display("TEST 001_blink ... PASS");
        $finish;
    end
endmodule
