`timescale 1ns/1ps
module tb_top;
    localparam integer CLOCK_HZ = 100;
    localparam integer BAUD_RATE = 10;
    localparam integer CYCLES_PER_BIT = CLOCK_HZ / BAUD_RATE;
    reg clk = 0;
    reg reset_button = 1;
    wire led_ready, led_done, uart_tx, sdram_clk, sdram_cs;
    wire sdram_ras_n, sdram_cas_n, sdram_we_n;
    wire [12:0] sdram_addr;
    wire [1:0] sdram_ba, sdram_dqm;
    wire [15:0] sdram_dq;
    wire model_init_ok;
    wire [31:0] refresh_count, write_bursts, read_bursts;
    reg [7:0] received;
    string expected;
    integer byte_index, bit_index;

    top #(
        .CLOCK_HZ(CLOCK_HZ), .BAUD_RATE(BAUD_RATE),
        .INIT_WAIT_CYCLES(8), .REFRESH_INTERVAL_CYCLES(80), .TOTAL_BURSTS(8)
    ) dut (.*);
    sdram_model #(.WORDS_PER_CHIP(512)) memory (
        .sdram_clk(sdram_clk), .sdram_cs(sdram_cs),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n), .sdram_addr(sdram_addr),
        .sdram_ba(sdram_ba), .sdram_dqm(sdram_dqm), .sdram_dq(sdram_dq),
        .init_ok(model_init_ok), .refresh_count(refresh_count),
        .write_burst_count(write_bursts), .read_burst_count(read_bursts)
    );
    always #5 clk = ~clk;

    initial begin
        expected = "TEST 009_sdram_uart ... PASS errors=0x00000000 first=0x0000000\r\n";
        repeat (3) @(posedge clk); reset_button = 0;
        for (byte_index = 0; byte_index < 64; byte_index = byte_index + 1) begin
            @(negedge uart_tx);
            repeat (CYCLES_PER_BIT / 2) @(posedge clk);
            if (uart_tx !== 1'b0) begin
                $display("TEST 009_sdram_uart ... FAIL (start bit)"); $fatal(1);
            end
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                repeat (CYCLES_PER_BIT) @(posedge clk);
                received[bit_index] = uart_tx;
            end
            repeat (CYCLES_PER_BIT) @(posedge clk);
            if (uart_tx !== 1'b1 || received !==
                (byte_index == 62 ? 8'h0d :
                 byte_index == 63 ? 8'h0a : expected[byte_index])) begin
                $display("TEST 009_sdram_uart ... FAIL (byte=%0d exp=%02x got=%02x)",
                         byte_index, expected[byte_index], received);
                $fatal(1);
            end
        end
        @(posedge clk); #1;
        if (!dut.report_done || !dut.bist_pass || dut.error_count != 0) begin
            $display("TEST 009_sdram_uart ... FAIL (report status)"); $fatal(1);
        end
        $display("TEST 009_sdram_uart ... PASS");
        $finish;
    end

    initial begin
        repeat (30_000) @(posedge clk);
        $display("TEST 009_sdram_uart ... FAIL (timeout)");
        $fatal(1);
    end
endmodule
