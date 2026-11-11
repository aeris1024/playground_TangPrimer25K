module top #(
    parameter integer INIT_WAIT_CYCLES = 10_000,
    parameter integer REFRESH_INTERVAL_CYCLES = 350
) (
    input  wire        clk,
    input  wire        reset_button,
    output wire        led_ready,
    output wire        led_done,
    output wire        uart_tx,
    output wire        sdram_clk,
    output wire        sdram_cs,
    output wire        sdram_ras_n,
    output wire        sdram_cas_n,
    output wire        sdram_we_n,
    output wire [12:0] sdram_addr,
    output wire [1:0]  sdram_ba,
    output wire [1:0]  sdram_dqm,
    inout  wire [15:0] sdram_dq
);
    wire init_done;
    wire controller_busy;
    reg [2:0] reset_pipe = 3'b000;
    wire system_reset = reset_button || !reset_pipe[2];
    always @(posedge clk) reset_pipe <= {reset_pipe[1:0], 1'b1};

    sdram_controller #(
        .INIT_WAIT_CYCLES(INIT_WAIT_CYCLES),
        .REFRESH_INTERVAL_CYCLES(REFRESH_INTERVAL_CYCLES)
    ) controller (
        .clk(clk),
        .reset(system_reset),
        .cmd_valid(1'b0),
        .cmd_ready(),
        .cmd_write(1'b0),
        .cmd_address(25'd0),
        .write_data(16'd0),
        .write_mask(2'b00),
        .write_index(),
        .read_valid(),
        .read_data(),
        .read_index(),
        .cmd_done(),
        .busy(controller_busy),
        .init_done(init_done),
        .sdram_clk(sdram_clk),
        .sdram_cs(sdram_cs),
        .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n),
        .sdram_addr(sdram_addr),
        .sdram_ba(sdram_ba),
        .sdram_dqm(sdram_dqm),
        .sdram_dq(sdram_dq)
    );

    // Dock LEDs are active high: READY means initialized, DONE pulses off only
    // while the controller is servicing a refresh.
    assign led_ready = init_done;
    assign led_done = init_done && !controller_busy;
    assign uart_tx = 1'b1;
endmodule
