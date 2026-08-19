module top #(
    parameter integer CLOCK_HZ = 50_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer INIT_WAIT_CYCLES = 10_000,
    parameter integer REFRESH_INTERVAL_CYCLES = 350,
    parameter integer TOTAL_BURSTS = 4_194_304
) (
    input wire clk, input wire reset_button,
    output wire led_ready, output wire led_done, output wire uart_tx,
    output wire sdram_clk, output wire sdram_cs,
    output wire sdram_ras_n, output wire sdram_cas_n, output wire sdram_we_n,
    output wire [12:0] sdram_addr, output wire [1:0] sdram_ba,
    output wire [1:0] sdram_dqm, inout wire [15:0] sdram_dq
);
    wire init_done, cmd_valid, cmd_ready, cmd_write, cmd_done;
    wire [24:0] cmd_address;
    wire [2:0] write_index, read_index;
    wire [15:0] write_data, read_data;
    wire [1:0] write_mask;
    wire read_valid, bist_done, bist_pass, bist_fail;
    wire [31:0] error_count;
    wire [24:0] first_error_address;
    wire [3:0] progress;
    wire uart_busy, uart_start;
    wire [7:0] uart_data;
    wire report_done;
    reg [2:0] reset_pipe = 3'b000;
    wire system_reset = reset_button || !reset_pipe[2];
    always @(posedge clk) reset_pipe <= {reset_pipe[1:0], 1'b1};

    sdram_controller #(
        .INIT_WAIT_CYCLES(INIT_WAIT_CYCLES),
        .REFRESH_INTERVAL_CYCLES(REFRESH_INTERVAL_CYCLES)
    ) controller (
        .clk(clk), .reset(system_reset), .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready), .cmd_write(cmd_write), .cmd_address(cmd_address),
        .write_data(write_data), .write_mask(write_mask), .write_index(write_index),
        .read_valid(read_valid), .read_data(read_data), .read_index(read_index),
        .cmd_done(cmd_done), .busy(), .init_done(init_done),
        .sdram_clk(sdram_clk), .sdram_cs(sdram_cs),
        .sdram_ras_n(sdram_ras_n), .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n), .sdram_addr(sdram_addr),
        .sdram_ba(sdram_ba), .sdram_dqm(sdram_dqm), .sdram_dq(sdram_dq)
    );

    sdram_bist #(.TOTAL_BURSTS(TOTAL_BURSTS)) bist (
        .clk(clk), .reset(system_reset), .init_done(init_done),
        .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_write(cmd_write),
        .cmd_address(cmd_address), .write_index(write_index),
        .write_data(write_data), .write_mask(write_mask),
        .read_valid(read_valid), .read_data(read_data), .read_index(read_index),
        .cmd_done(cmd_done), .done(bist_done), .pass(bist_pass), .fail(bist_fail),
        .error_count(error_count), .first_error_address(first_error_address),
        .progress(progress)
    );

    bist_uart_reporter reporter (
        .clk(clk), .reset(system_reset), .bist_done(bist_done),
        .bist_pass(bist_pass), .error_count(error_count),
        .first_error_address(first_error_address), .uart_busy(uart_busy),
        .uart_start(uart_start), .uart_data(uart_data), .report_done(report_done)
    );

    uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD_RATE(BAUD_RATE)) serial (
        .clk(clk), .start(uart_start), .data(uart_data),
        .tx(uart_tx), .busy(uart_busy)
    );

    assign led_ready = ~bist_pass;
    assign led_done = ~bist_fail;
endmodule
