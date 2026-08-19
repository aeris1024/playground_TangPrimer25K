module top (
    input  wire button_s1,
    input  wire button_s2,
    output wire led_ready,
    output wire led_done
);
    // Dock status LEDs are active-low; buttons are active-high with pull-downs.
    assign led_ready = ~button_s1;
    assign led_done  = ~button_s2;
endmodule
