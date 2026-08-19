// Simple fixed-BL8 controller for the Sipeed Tang 40-pin 64 MB SDRAM module.
// The module exposes one 16-bit bus; sdram_cs selects either 32 MB device.
module sdram_controller #(
    parameter integer INIT_WAIT_CYCLES = 10_000,
    parameter integer REFRESH_INTERVAL_CYCLES = 350,
    parameter integer T_RP_CYCLES = 1,
    parameter integer T_RCD_CYCLES = 1,
    parameter integer T_RC_CYCLES = 4,
    parameter integer T_MRD_CYCLES = 2,
    parameter integer T_WR_CYCLES = 2,
    parameter integer CAS_LATENCY = 2
) (
    input  wire        clk,
    input  wire        reset,

    input  wire        cmd_valid,
    output wire        cmd_ready,
    input  wire        cmd_write,
    input  wire [24:0] cmd_address,
    input  wire [15:0] write_data,
    input  wire [1:0]  write_mask,
    output wire [2:0]  write_index,
    output reg         read_valid,
    output reg  [15:0] read_data,
    output reg  [2:0]  read_index,
    output reg         cmd_done,
    output wire        busy,
    output reg         init_done,

    output wire        sdram_clk,
    output reg         sdram_cs,
    output reg         sdram_ras_n,
    output reg         sdram_cas_n,
    output reg         sdram_we_n,
    output reg  [12:0] sdram_addr,
    output reg  [1:0]  sdram_ba,
    output reg  [1:0]  sdram_dqm,
    inout  wire [15:0] sdram_dq
);
    localparam [4:0]
        ST_INIT_WAIT    = 5'd0,
        ST_INIT_PRE     = 5'd1,
        ST_INIT_TRP     = 5'd2,
        ST_INIT_REF     = 5'd3,
        ST_INIT_TRC     = 5'd4,
        ST_INIT_MRS     = 5'd5,
        ST_INIT_MRD     = 5'd6,
        ST_IDLE         = 5'd7,
        ST_ACTIVATE     = 5'd8,
        ST_RCD_WAIT     = 5'd9,
        ST_RW_COMMAND   = 5'd10,
        ST_WRITE_DATA   = 5'd11,
        ST_WRITE_RELEASE= 5'd12,
        ST_WRITE_WAIT   = 5'd13,
        ST_READ_LATENCY = 5'd14,
        ST_READ_DATA    = 5'd15,
        ST_READ_WAIT    = 5'd16,
        ST_REFRESH_0    = 5'd17,
        ST_REFRESH_WAIT0= 5'd18,
        ST_REFRESH_1    = 5'd19,
        ST_REFRESH_WAIT1= 5'd20;

    localparam [2:0]
        CMD_MRS     = 3'b000,
        CMD_REFRESH = 3'b001,
        CMD_PRE     = 3'b010,
        CMD_ACT     = 3'b011,
        CMD_WRITE   = 3'b100,
        CMD_READ    = 3'b101,
        CMD_NOP     = 3'b111;

    // BL=8, sequential, CAS=2, standard write burst.
    localparam [12:0] MODE_REGISTER = 13'h023;

    reg [4:0] state = ST_INIT_WAIT;
    reg [31:0] wait_count = 32'd0;
    reg [31:0] refresh_count = 32'd0;
    reg init_chip = 1'b0;
    reg [3:0] init_refresh_count = 4'd0;
    reg transaction_write = 1'b0;
    reg [24:0] transaction_address = 25'd0;
    reg [2:0] beat_index = 3'd0;
    reg dq_output_enable = 1'b0;
    reg [15:0] dq_output = 16'h0000;

    assign sdram_clk = ~clk;
    assign sdram_dq = dq_output_enable ? dq_output : 16'hzzzz;
    assign write_index = beat_index;
    assign busy = !init_done || state != ST_IDLE;
    assign cmd_ready = init_done && state == ST_IDLE &&
                       refresh_count < REFRESH_INTERVAL_CYCLES - 1;

    task automatic issue_command(input [2:0] command);
        begin
            {sdram_ras_n, sdram_cas_n, sdram_we_n} <= command;
        end
    endtask

    always @(posedge clk) begin
        issue_command(CMD_NOP);
        sdram_addr <= 13'h0000;
        sdram_ba <= 2'b00;
        sdram_dqm <= 2'b11;
        read_valid <= 1'b0;
        cmd_done <= 1'b0;

        if (reset) begin
            state <= ST_INIT_WAIT;
            wait_count <= 32'd0;
            refresh_count <= 32'd0;
            init_chip <= 1'b0;
            init_refresh_count <= 4'd0;
            init_done <= 1'b0;
            read_valid <= 1'b0;
            read_data <= 16'h0000;
            read_index <= 3'd0;
            cmd_done <= 1'b0;
            dq_output_enable <= 1'b0;
            sdram_cs <= 1'b0;
            sdram_ras_n <= 1'b1;
            sdram_cas_n <= 1'b1;
            sdram_we_n <= 1'b1;
            sdram_addr <= 13'h0000;
            sdram_ba <= 2'b00;
            sdram_dqm <= 2'b11;
            beat_index <= 3'd0;
        end else begin
            if (init_done && refresh_count < REFRESH_INTERVAL_CYCLES)
                refresh_count <= refresh_count + 1'b1;

            case (state)
                ST_INIT_WAIT: begin
                    if (wait_count == INIT_WAIT_CYCLES - 1) begin
                        wait_count <= 32'd0;
                        state <= ST_INIT_PRE;
                    end else begin
                        wait_count <= wait_count + 1'b1;
                    end
                end

                ST_INIT_PRE: begin
                    sdram_cs <= init_chip;
                    sdram_addr[10] <= 1'b1;
                    issue_command(CMD_PRE);
                    wait_count <= T_RP_CYCLES - 1;
                    state <= ST_INIT_TRP;
                end

                ST_INIT_TRP: begin
                    if (wait_count == 0) state <= ST_INIT_REF;
                    else wait_count <= wait_count - 1'b1;
                end

                ST_INIT_REF: begin
                    sdram_cs <= init_chip;
                    issue_command(CMD_REFRESH);
                    init_refresh_count <= init_refresh_count + 1'b1;
                    wait_count <= T_RC_CYCLES - 1;
                    state <= ST_INIT_TRC;
                end

                ST_INIT_TRC: begin
                    if (wait_count == 0) begin
                        if (init_refresh_count == 8) state <= ST_INIT_MRS;
                        else state <= ST_INIT_REF;
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                ST_INIT_MRS: begin
                    sdram_cs <= init_chip;
                    sdram_addr <= MODE_REGISTER;
                    issue_command(CMD_MRS);
                    wait_count <= T_MRD_CYCLES - 1;
                    state <= ST_INIT_MRD;
                end

                ST_INIT_MRD: begin
                    if (wait_count == 0) begin
                        if (!init_chip) begin
                            init_chip <= 1'b1;
                            init_refresh_count <= 4'd0;
                            state <= ST_INIT_PRE;
                        end else begin
                            init_done <= 1'b1;
                            refresh_count <= 32'd0;
                            state <= ST_IDLE;
                        end
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                ST_IDLE: begin
                    dq_output_enable <= 1'b0;
                    if (refresh_count >= REFRESH_INTERVAL_CYCLES - 1) begin
                        state <= ST_REFRESH_0;
                    end else if (cmd_valid) begin
                        transaction_write <= cmd_write;
                        transaction_address <= cmd_address;
                        beat_index <= 3'd0;
                        state <= ST_ACTIVATE;
                    end
                end

                ST_ACTIVATE: begin
                    sdram_cs <= transaction_address[24];
                    sdram_ba <= transaction_address[10:9];
                    sdram_addr <= transaction_address[23:11];
                    issue_command(CMD_ACT);
                    wait_count <= T_RCD_CYCLES - 1;
                    state <= ST_RCD_WAIT;
                end

                ST_RCD_WAIT: begin
                    if (wait_count == 0) state <= ST_RW_COMMAND;
                    else wait_count <= wait_count - 1'b1;
                end

                ST_RW_COMMAND: begin
                    sdram_cs <= transaction_address[24];
                    sdram_ba <= transaction_address[10:9];
                    sdram_addr[8:0] <= transaction_address[8:0];
                    sdram_addr[10] <= 1'b1;
                    sdram_dqm <= write_mask;
                    beat_index <= 3'd0;
                    if (transaction_write) begin
                        issue_command(CMD_WRITE);
                        dq_output_enable <= 1'b1;
                        dq_output <= write_data;
                        state <= ST_WRITE_DATA;
                        beat_index <= 3'd1;
                    end else begin
                        issue_command(CMD_READ);
                        wait_count <= CAS_LATENCY - 1;
                        state <= ST_READ_LATENCY;
                    end
                end

                ST_WRITE_DATA: begin
                    sdram_dqm <= write_mask;
                    dq_output <= write_data;
                    if (beat_index == 3'd7) begin
                        state <= ST_WRITE_RELEASE;
                    end else begin
                        beat_index <= beat_index + 1'b1;
                    end
                end

                ST_WRITE_RELEASE: begin
                    dq_output_enable <= 1'b0;
                    wait_count <= T_WR_CYCLES + T_RP_CYCLES - 1;
                    state <= ST_WRITE_WAIT;
                end

                ST_WRITE_WAIT: begin
                    if (wait_count == 0) begin
                        cmd_done <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                ST_READ_LATENCY: begin
                    if (wait_count == 0) begin
                        beat_index <= 3'd0;
                        state <= ST_READ_DATA;
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                ST_READ_DATA: begin
                    read_data <= sdram_dq;
                    read_valid <= 1'b1;
                    read_index <= beat_index;
                    if (beat_index == 3'd7) begin
                        wait_count <= T_RP_CYCLES - 1;
                        state <= ST_READ_WAIT;
                    end else begin
                        beat_index <= beat_index + 1'b1;
                    end
                end

                ST_READ_WAIT: begin
                    if (wait_count == 0) begin
                        cmd_done <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                ST_REFRESH_0: begin
                    sdram_cs <= 1'b0;
                    issue_command(CMD_REFRESH);
                    wait_count <= T_RC_CYCLES - 1;
                    state <= ST_REFRESH_WAIT0;
                end

                ST_REFRESH_WAIT0: begin
                    if (wait_count == 0) state <= ST_REFRESH_1;
                    else wait_count <= wait_count - 1'b1;
                end

                ST_REFRESH_1: begin
                    sdram_cs <= 1'b1;
                    issue_command(CMD_REFRESH);
                    wait_count <= T_RC_CYCLES - 1;
                    state <= ST_REFRESH_WAIT1;
                end

                ST_REFRESH_WAIT1: begin
                    if (wait_count == 0) begin
                        refresh_count <= 32'd0;
                        state <= ST_IDLE;
                    end else begin
                        wait_count <= wait_count - 1'b1;
                    end
                end

                default: state <= ST_INIT_WAIT;
            endcase
        end
    end
endmodule
