`timescale 1ns/1ps

module pll_50_to_100 (
    input  wire clk_in,
    output wire clk_out,
    output wire locked
);
`ifdef __ICARUS__
    reg sim_clock = 1'b0;
    reg sim_locked = 1'b0;

    assign clk_out = sim_clock;
    assign locked = sim_locked;

    always #5 sim_clock = ~sim_clock;
    initial begin
        #100 sim_locked = 1'b1;
    end
`else
    wire unused_clkout1;
    wire unused_clkout2;
    wire unused_clkout3;
    wire unused_clkout4;
    wire unused_clkout5;
    wire unused_clkout6;
    wire unused_clkfbout;
    wire [7:0] unused_mdrdo;

    PLLA pll_inst (
        .LOCK(locked),
        .CLKOUT0(clk_out),
        .CLKOUT1(unused_clkout1),
        .CLKOUT2(unused_clkout2),
        .CLKOUT3(unused_clkout3),
        .CLKOUT4(unused_clkout4),
        .CLKOUT5(unused_clkout5),
        .CLKOUT6(unused_clkout6),
        .CLKFBOUT(unused_clkfbout),
        .CLKIN(clk_in),
        .CLKFB(1'b0),
        .RESET(1'b0),
        .PLLPWD(1'b0),
        .RESET_I(1'b0),
        .RESET_O(1'b0),
        .PSSEL(3'b000),
        .PSDIR(1'b0),
        .PSPULSE(1'b0),
        .SSCPOL(1'b0),
        .SSCON(1'b0),
        .SSCMDSEL(7'b0000000),
        .SSCMDSEL_FRAC(3'b000),
        .MDCLK(1'b0),
        .MDOPC(2'b00),
        .MDAINC(1'b0),
        .MDWDI(8'h00),
        .MDRDO(unused_mdrdo)
    );

    defparam pll_inst.FCLKIN = "50.0";
    defparam pll_inst.IDIV_SEL = 1;
    defparam pll_inst.FBDIV_SEL = 1;
    defparam pll_inst.MDIV_SEL = 16;
    defparam pll_inst.MDIV_FRAC_SEL = 0;
    defparam pll_inst.ODIV0_SEL = 8;
    defparam pll_inst.ODIV0_FRAC_SEL = 0;
    defparam pll_inst.CLKFB_SEL = "INTERNAL";
    defparam pll_inst.CLKOUT0_EN = "TRUE";
    defparam pll_inst.CLKOUT1_EN = "FALSE";
    defparam pll_inst.CLKOUT2_EN = "FALSE";
    defparam pll_inst.CLKOUT3_EN = "FALSE";
    defparam pll_inst.CLKOUT4_EN = "FALSE";
    defparam pll_inst.CLKOUT5_EN = "FALSE";
    defparam pll_inst.CLKOUT6_EN = "FALSE";
`endif
endmodule
