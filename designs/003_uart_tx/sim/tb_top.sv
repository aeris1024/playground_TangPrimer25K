`timescale 1ns/1ps

module tb_top;
    localparam integer CLOCK_HZ = 100;
    localparam integer BAUD_RATE = 10;
    localparam integer CYCLES_PER_BIT = CLOCK_HZ / BAUD_RATE;

    reg clk = 1'b0;
    wire uart_tx_pin;
    reg [7:0] received [0:13];
    reg [7:0] expected [0:13];
    integer byte_index;
    integer bit_index;

    top #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD_RATE(BAUD_RATE),
        .REPEAT_CYCLES(20)
    ) dut (
        .clk(clk),
        .uart_tx_pin(uart_tx_pin)
    );

    always #5 clk = ~clk;

    initial begin
        expected[0] = "F"; expected[1] = "P"; expected[2] = "G"; expected[3] = "A";
        expected[4] = " "; expected[5] = "U"; expected[6] = "A"; expected[7] = "R";
        expected[8] = "T"; expected[9] = " "; expected[10] = "T"; expected[11] = "X";
        expected[12] = 8'h0d; expected[13] = 8'h0a;

        for (byte_index = 0; byte_index < 14; byte_index = byte_index + 1) begin
            @(negedge uart_tx_pin);
            repeat (CYCLES_PER_BIT / 2) @(posedge clk);
            if (uart_tx_pin !== 1'b0) begin
                $display("TEST 003_uart_tx ... FAIL (invalid start bit)");
                $fatal(1);
            end
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                repeat (CYCLES_PER_BIT) @(posedge clk);
                received[byte_index][bit_index] = uart_tx_pin;
            end
            repeat (CYCLES_PER_BIT) @(posedge clk);
            if (uart_tx_pin !== 1'b1) begin
                $display("TEST 003_uart_tx ... FAIL (invalid stop bit)");
                $fatal(1);
            end
            if (received[byte_index] !== expected[byte_index]) begin
                $display("TEST 003_uart_tx ... FAIL (byte %0d expected=%02x actual=%02x)",
                         byte_index, expected[byte_index], received[byte_index]);
                $fatal(1);
            end
        end

        $display("TEST 003_uart_tx ... PASS");
        $finish;
    end
endmodule
