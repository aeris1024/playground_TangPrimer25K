module burst_test (
    input  wire        clk,
    input  wire        reset,
    input  wire        init_done,
    output reg         cmd_valid,
    input  wire        cmd_ready,
    output reg         cmd_write,
    output reg  [24:0] cmd_address,
    input  wire [2:0]  write_index,
    output wire [15:0] write_data,
    output wire [1:0]  write_mask,
    input  wire        read_valid,
    input  wire [15:0] read_data,
    input  wire [2:0]  read_index,
    input  wire        cmd_done,
    output reg         done,
    output reg         pass,
    output reg         fail,
    output reg  [3:0]  beats_seen
);
    localparam [2:0] WAIT_INIT = 3'd0, WRITE_ISSUE = 3'd1,
                     WRITE_WAIT = 3'd2, READ_ISSUE = 3'd3,
                     READ_WAIT = 3'd4, FINISHED = 3'd5;
    reg [2:0] state = WAIT_INIT;
    reg previous_read_valid = 1'b0;
    reg mismatch = 1'b0;

    assign write_data = 16'hb000 + write_index;
    assign write_mask = 2'b00;

    always @(posedge clk) begin
        if (reset) begin
            state <= WAIT_INIT;
            cmd_valid <= 1'b0;
            cmd_write <= 1'b0;
            cmd_address <= 25'h0000020;
            done <= 1'b0;
            pass <= 1'b0;
            fail <= 1'b0;
            beats_seen <= 4'd0;
            previous_read_valid <= 1'b0;
            mismatch <= 1'b0;
        end else begin
            if (read_valid) begin
                if (beats_seen != 0 && !previous_read_valid)
                    mismatch <= 1'b1;
                if (read_data !== 16'hb000 + read_index)
                    mismatch <= 1'b1;
                beats_seen <= beats_seen + 1'b1;
            end
            previous_read_valid <= read_valid;

            case (state)
                WAIT_INIT: if (init_done) begin
                    cmd_write <= 1'b1;
                    cmd_valid <= 1'b1;
                    state <= WRITE_ISSUE;
                end
                WRITE_ISSUE: if (cmd_valid && cmd_ready) begin
                    cmd_valid <= 1'b0;
                    state <= WRITE_WAIT;
                end
                WRITE_WAIT: if (cmd_done) begin
                    cmd_write <= 1'b0;
                    cmd_valid <= 1'b1;
                    state <= READ_ISSUE;
                end
                READ_ISSUE: if (cmd_valid && cmd_ready) begin
                    cmd_valid <= 1'b0;
                    state <= READ_WAIT;
                end
                READ_WAIT: if (cmd_done) begin
                    done <= 1'b1;
                    pass <= !mismatch && beats_seen == 8;
                    fail <= mismatch || beats_seen != 8;
                    state <= FINISHED;
                end
                default: cmd_valid <= 1'b0;
            endcase
        end
    end
endmodule
