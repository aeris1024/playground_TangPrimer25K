`timescale 1ns/1ps

module tb_top;
    localparam integer TEST_ADDR_WIDTH = 4;

    reg clk = 1'b0;
    wire led_ready;
    wire led_done;

    top #(
        .ADDR_WIDTH(TEST_ADDR_WIDTH),
        .DATA_WIDTH(16)
    ) dut (
        .clk(clk),
        .led_ready(led_ready),
        .led_done(led_done)
    );

    always #5 clk = ~clk;

    initial begin
        repeat (100) begin
            @(posedge clk);
            #1;
            if (led_done === 1'b1) begin
                $display("TEST 005_bram ... FAIL (BIST mismatch at address %0d)",
                         dut.address);
                $fatal(1);
            end
            if (led_ready === 1'b1) begin
                $display("TEST 005_bram ... PASS");
                $finish;
            end
        end

        $display("TEST 005_bram ... FAIL (BIST timeout)");
        $fatal(1);
    end
endmodule
