`timescale 1ns/1ps

module tb_top;
    reg button_s1 = 1'b0;
    reg button_s2 = 1'b0;
    wire led_ready;
    wire led_done;

    integer pattern;

    top dut (
        .button_s1(button_s1),
        .button_s2(button_s2),
        .led_ready(led_ready),
        .led_done(led_done)
    );

    initial begin
        for (pattern = 0; pattern < 4; pattern = pattern + 1) begin
            {button_s2, button_s1} = pattern[1:0];
            #1;
            if (led_ready !== ~button_s1 || led_done !== ~button_s2) begin
                $display(
                    "TEST 002_button ... FAIL (buttons=%b%b leds=%b%b)",
                    button_s2,
                    button_s1,
                    led_done,
                    led_ready
                );
                $fatal(1);
            end
        end

        $display("TEST 002_button ... PASS");
        $finish;
    end
endmodule
