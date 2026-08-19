`timescale 1ns/1ps

module tb_top;
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

    top #(.INIT_WAIT_CYCLES(8), .REFRESH_INTERVAL_CYCLES(40)) dut (.*);
    sdram_model #(.WORDS_PER_CHIP(256)) memory (
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
        repeat (300) begin
            @(posedge clk); #1;
            if (dut.init_done) begin
                if (!model_init_ok || led_ready !== 1'b0 || refresh_count < 16) begin
                    $display("TEST 006_sdram_init ... FAIL (bad initialization sequence)");
                    $fatal(1);
                end
                $display("TEST 006_sdram_init ... PASS");
                $finish;
            end
        end
        $display("TEST 006_sdram_init ... FAIL (timeout)");
        $fatal(1);
    end
endmodule
