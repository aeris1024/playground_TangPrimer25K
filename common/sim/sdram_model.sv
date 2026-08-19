`ifdef __ICARUS__
// Compact behavioral model for controller-level tests. It models the command
// protocol and BL8 transfers, while intentionally storing only a configurable
// window from each 32 MB device.
module sdram_model #(
    parameter integer WORDS_PER_CHIP = 4096,
    parameter integer CAS_LATENCY = 2
) (
    input  wire        sdram_clk,
    input  wire        sdram_cs,
    input  wire        sdram_ras_n,
    input  wire        sdram_cas_n,
    input  wire        sdram_we_n,
    input  wire [12:0] sdram_addr,
    input  wire [1:0]  sdram_ba,
    input  wire [1:0]  sdram_dqm,
    inout  wire [15:0] sdram_dq,
    output wire        init_ok,
    output reg  [31:0] refresh_count = 32'd0,
    output reg  [31:0] write_burst_count = 32'd0,
    output reg  [31:0] read_burst_count = 32'd0
);
    localparam [2:0]
        CMD_MRS     = 3'b000,
        CMD_REFRESH = 3'b001,
        CMD_PRE     = 3'b010,
        CMD_ACT     = 3'b011,
        CMD_WRITE   = 3'b100,
        CMD_READ    = 3'b101;

    reg [15:0] memory [0:2*WORDS_PER_CHIP-1];
    reg [12:0] open_row [0:7];
    reg [7:0] row_open = 8'h00;
    reg [3:0] refresh_by_chip [0:1];
    reg [1:0] precharged = 2'b00;
    reg [1:0] mode_loaded = 2'b00;

    reg dq_output_enable = 1'b0;
    reg [15:0] dq_output = 16'h0000;
    reg write_active = 1'b0;
    reg write_chip = 1'b0;
    reg [1:0] write_bank = 2'b00;
    reg [12:0] write_row = 13'd0;
    reg [8:0] write_column = 9'd0;
    reg [3:0] write_remaining = 4'd0;
    reg read_active = 1'b0;
    reg read_chip = 1'b0;
    reg [1:0] read_bank = 2'b00;
    reg [12:0] read_row = 13'd0;
    reg [8:0] read_column = 9'd0;
    reg [3:0] read_remaining = 4'd0;
    reg [3:0] read_delay = 4'd0;

    integer i;
    integer index_value;

    assign sdram_dq = dq_output_enable ? dq_output : 16'hzzzz;
    assign init_ok = &precharged && &mode_loaded &&
                     refresh_by_chip[0] >= 2 && refresh_by_chip[1] >= 2;

    function automatic integer memory_index(
        input chip,
        input [1:0] bank,
        input [12:0] row,
        input [8:0] column
    );
        reg [23:0] linear;
        begin
            linear = {row, bank, column};
            memory_index = chip * WORDS_PER_CHIP + (linear % WORDS_PER_CHIP);
        end
    endfunction

    initial begin
        refresh_by_chip[0] = 0;
        refresh_by_chip[1] = 0;
        for (i = 0; i < 2*WORDS_PER_CHIP; i = i + 1)
            memory[i] = 16'hxxxx;
    end

    always @(posedge sdram_clk) begin
        dq_output_enable <= 1'b0;

        if (write_active) begin
            index_value = memory_index(write_chip, write_bank, write_row, write_column);
            if (!sdram_dqm[0]) memory[index_value][7:0] <= sdram_dq[7:0];
            if (!sdram_dqm[1]) memory[index_value][15:8] <= sdram_dq[15:8];
            write_column <= write_column + 1'b1;
            write_remaining <= write_remaining - 1'b1;
            if (write_remaining == 1) begin
                write_active <= 1'b0;
                row_open[{write_chip, write_bank}] <= 1'b0;
            end
        end

        if (read_active) begin
            if (read_delay != 0) begin
                read_delay <= read_delay - 1'b1;
            end else if (read_remaining != 0) begin
                index_value = memory_index(read_chip, read_bank, read_row, read_column);
                dq_output <= memory[index_value];
                dq_output_enable <= 1'b1;
                read_column <= read_column + 1'b1;
                read_remaining <= read_remaining - 1'b1;
                if (read_remaining == 1) begin
                    read_active <= 1'b0;
                    row_open[{read_chip, read_bank}] <= 1'b0;
                end
            end
        end

        case ({sdram_ras_n, sdram_cas_n, sdram_we_n})
            CMD_PRE: begin
                if (sdram_addr[10]) begin
                    row_open[{sdram_cs, 2'b00} +: 4] <= 4'b0000;
                    precharged[sdram_cs] <= 1'b1;
                end
            end
            CMD_REFRESH: begin
                if (refresh_by_chip[sdram_cs] != 15)
                    refresh_by_chip[sdram_cs] <= refresh_by_chip[sdram_cs] + 1'b1;
                refresh_count <= refresh_count + 1'b1;
            end
            CMD_MRS: begin
                if (sdram_addr[6:4] == CAS_LATENCY && sdram_addr[2:0] == 3'b011)
                    mode_loaded[sdram_cs] <= 1'b1;
            end
            CMD_ACT: begin
                open_row[{sdram_cs, sdram_ba}] <= sdram_addr;
                row_open[{sdram_cs, sdram_ba}] <= 1'b1;
            end
            CMD_WRITE: begin
                if (!row_open[{sdram_cs, sdram_ba}]) begin
                    $display("SDRAM MODEL ERROR: WRITE without ACTIVATE");
                    $fatal(1);
                end
                index_value = memory_index(
                    sdram_cs, sdram_ba, open_row[{sdram_cs, sdram_ba}], sdram_addr[8:0]
                );
                if (!sdram_dqm[0]) memory[index_value][7:0] <= sdram_dq[7:0];
                if (!sdram_dqm[1]) memory[index_value][15:8] <= sdram_dq[15:8];
                write_chip <= sdram_cs;
                write_bank <= sdram_ba;
                write_row <= open_row[{sdram_cs, sdram_ba}];
                write_column <= sdram_addr[8:0] + 1'b1;
                write_remaining <= 4'd7;
                write_active <= 1'b1;
                write_burst_count <= write_burst_count + 1'b1;
            end
            CMD_READ: begin
                if (!row_open[{sdram_cs, sdram_ba}]) begin
                    $display("SDRAM MODEL ERROR: READ without ACTIVATE");
                    $fatal(1);
                end
                read_chip <= sdram_cs;
                read_bank <= sdram_ba;
                read_row <= open_row[{sdram_cs, sdram_ba}];
                read_column <= sdram_addr[8:0];
                read_remaining <= 4'd8;
                read_delay <= CAS_LATENCY - 1;
                read_active <= 1'b1;
                read_burst_count <= read_burst_count + 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
`endif
