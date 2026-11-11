`timescale 1ns/1ps

module tb_top;
    localparam integer TEST_HALF_CYCLES = 4;

    reg clk = 1'b0;
    wire led_ready;
    wire led_done;
    integer toggle_count = 0;
    reg previous_ready;
    time previous_pll_edge = 0;
    integer pll_edge_count = 0;

    top #(
        .HEARTBEAT_HALF_CYCLES(TEST_HALF_CYCLES)
    ) dut (
        .clk(clk),
        .led_ready(led_ready),
        .led_done(led_done)
    );

    always #10 clk = ~clk;

    always @(posedge dut.pll_clock) begin
        if (dut.pll_locked) begin
            if (pll_edge_count > 0 && $time - previous_pll_edge != 10) begin
                $display("TEST 004_pll ... FAIL (PLL period=%0t)",
                         $time - previous_pll_edge);
                $fatal(1);
            end
            previous_pll_edge = $time;
            pll_edge_count = pll_edge_count + 1;
        end
    end

    initial begin
        previous_ready = led_ready;
        wait (dut.pll_locked === 1'b1);
        #1;
        if (led_done !== 1'b1) begin
            $display("TEST 004_pll ... FAIL (LOCK LED is off)");
            $fatal(1);
        end

        repeat (TEST_HALF_CYCLES * 5) begin
            @(posedge dut.pll_clock);
            #1;
            if (led_ready !== previous_ready) begin
                toggle_count = toggle_count + 1;
                previous_ready = led_ready;
            end
        end

        if (pll_edge_count < 10 || toggle_count < 4) begin
            $display("TEST 004_pll ... FAIL (edges=%0d toggles=%0d)",
                     pll_edge_count, toggle_count);
            $fatal(1);
        end

        $display("TEST 004_pll ... PASS");
        $finish;
    end
endmodule
