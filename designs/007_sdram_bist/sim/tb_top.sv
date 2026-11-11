`timescale 1ns/1ps

module tb_top;
    localparam integer TEST_BURSTS = 32;
    reg clk = 1'b0;
    reg reset_button = 1'b1;
    wire led_ready, led_done;
    wire uart_tx;
    wire sdram_clk, sdram_cs, sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [12:0] sdram_addr;
    wire [1:0] sdram_ba, sdram_dqm;
    wire [15:0] sdram_dq;
    wire model_init_ok;
    wire [31:0] refresh_count, write_bursts, read_bursts;

    top #(
        .INIT_WAIT_CYCLES(8), .REFRESH_INTERVAL_CYCLES(80),
        .TOTAL_BURSTS(TEST_BURSTS)
    ) dut (.*);
    sdram_model #(.WORDS_PER_CHIP(1024)) memory (
        .sdram_clk(sdram_clk), .sdram_cs(sdram_cs),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n), .sdram_addr(sdram_addr),
        .sdram_ba(sdram_ba), .sdram_dqm(sdram_dqm), .sdram_dq(sdram_dq),
        .init_ok(model_init_ok), .refresh_count(refresh_count),
        .write_burst_count(write_bursts), .read_burst_count(read_bursts)
    );
    always #5 clk = ~clk;

    initial begin
        repeat (3) @(posedge clk);
        reset_button = 1'b0;
        repeat (20_000) begin
            @(posedge clk); #1;
            if (dut.bist_done) begin
                if (!dut.bist_pass || dut.bist_fail ||
                    led_ready !== 1'b1 || led_done !== 1'b0 ||
                    dut.error_count != 0 ||
                    !model_init_ok || write_bursts != 8 * (TEST_BURSTS + 20) ||
                    read_bursts != 8 * (TEST_BURSTS + 20)) begin
                    $display("TEST 007_sdram_bist ... FAIL (errors=%0d wr=%0d rd=%0d)",
                             dut.error_count, write_bursts, read_bursts);
                    $fatal(1);
                end
                $display("TEST 007_sdram_bist ... PASS");
                $finish;
            end
        end
        $display("TEST 007_sdram_bist ... FAIL (timeout, phase=%0d)", dut.progress);
        $fatal(1);
    end
endmodule
