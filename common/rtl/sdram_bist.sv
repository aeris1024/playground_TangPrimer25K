module sdram_bist #(
    parameter integer TOTAL_BURSTS = 4_194_304
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        init_done,
    output reg         cmd_valid,
    input  wire        cmd_ready,
    output reg         cmd_write,
    output reg  [24:0] cmd_address,
    input  wire [2:0]  write_index,
    output reg  [15:0] write_data,
    output wire [1:0]  write_mask,
    input  wire        read_valid,
    input  wire [15:0] read_data,
    input  wire [2:0]  read_index,
    input  wire        cmd_done,
    output reg         done,
    output reg         pass,
    output reg         fail,
    output reg  [31:0] error_count,
    output reg  [24:0] first_error_address,
    output reg  [3:0]  progress
);
    localparam [3:0]
        PH_WAIT       = 4'd0,
        PH_FIXED_WR   = 4'd1,
        PH_FIXED_RD   = 4'd2,
        PH_WALK_WR    = 4'd3,
        PH_WALK_RD    = 4'd4,
        PH_FULL_WR    = 4'd5,
        PH_FULL_RD    = 4'd6,
        PH_DONE       = 4'd7;
    localparam [1:0] OP_ISSUE = 2'd0, OP_WAIT = 2'd1;

    reg [3:0] phase = PH_WAIT;
    reg [1:0] operation_state = OP_ISSUE;
    reg [1:0] fixed_pattern = 2'd0;
    reg [3:0] walking_bit = 4'd0;
    reg [31:0] burst_number = 32'd0;
    reg [15:0] expected_read;
    wire [24:0] read_word_address = cmd_address + read_index;
    wire [24:0] write_word_address = cmd_address + write_index;

    assign write_mask = 2'b00;

    function automatic [15:0] fixed_value(input [1:0] index);
        begin
            case (index)
                2'd0: fixed_value = 16'h0000;
                2'd1: fixed_value = 16'hffff;
                2'd2: fixed_value = 16'ha5a5;
                default: fixed_value = 16'h5a5a;
            endcase
        end
    endfunction

    function automatic [15:0] address_value(input [24:0] address);
        begin
            address_value = address[15:0] ^ {7'd0, address[24:16]} ^ 16'h3c5a;
        end
    endfunction

    always @* begin
        case (phase)
            PH_FIXED_WR: write_data = fixed_value(fixed_pattern);
            PH_WALK_WR:  write_data = 16'h0001 << walking_bit;
            default:     write_data = address_value(write_word_address);
        endcase

        case (phase)
            PH_FIXED_RD: expected_read = fixed_value(fixed_pattern);
            PH_WALK_RD:  expected_read = 16'h0001 << walking_bit;
            default:     expected_read = address_value(read_word_address);
        endcase
    end

    task automatic begin_operation(input write_operation, input [24:0] address);
        begin
            cmd_write <= write_operation;
            cmd_address <= address;
            cmd_valid <= 1'b1;
            operation_state <= OP_ISSUE;
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            phase <= PH_WAIT;
            operation_state <= OP_ISSUE;
            cmd_valid <= 1'b0;
            cmd_write <= 1'b0;
            cmd_address <= 25'd0;
            done <= 1'b0;
            pass <= 1'b0;
            fail <= 1'b0;
            error_count <= 32'd0;
            first_error_address <= 25'd0;
            progress <= 4'd0;
        end else begin
            if (read_valid && read_data !== expected_read) begin
                if (error_count == 0)
                    first_error_address <= read_word_address;
                if (error_count != 32'hffff_ffff)
                    error_count <= error_count + 1'b1;
            end

            if (operation_state == OP_ISSUE && cmd_valid && cmd_ready) begin
                cmd_valid <= 1'b0;
                operation_state <= OP_WAIT;
            end

            case (phase)
                PH_WAIT: if (init_done) begin
                    fixed_pattern <= 2'd0;
                    phase <= PH_FIXED_WR;
                    progress <= PH_FIXED_WR;
                    begin_operation(1'b1, 25'd0);
                end

                PH_FIXED_WR: if (operation_state == OP_WAIT && cmd_done) begin
                    if (fixed_pattern == 3) begin
                        fixed_pattern <= 2'd0;
                        phase <= PH_FIXED_RD;
                        progress <= PH_FIXED_RD;
                        begin_operation(1'b0, 25'd0);
                    end else begin
                        fixed_pattern <= fixed_pattern + 1'b1;
                        begin_operation(1'b1, {20'd0, fixed_pattern + 1'b1, 3'b000});
                    end
                end

                PH_FIXED_RD: if (operation_state == OP_WAIT && cmd_done) begin
                    if (fixed_pattern == 3) begin
                        walking_bit <= 4'd0;
                        phase <= PH_WALK_WR;
                        progress <= PH_WALK_WR;
                        begin_operation(1'b1, 25'h0000100);
                    end else begin
                        fixed_pattern <= fixed_pattern + 1'b1;
                        begin_operation(1'b0, {20'd0, fixed_pattern + 1'b1, 3'b000});
                    end
                end

                PH_WALK_WR: if (operation_state == OP_WAIT && cmd_done) begin
                    if (walking_bit == 15) begin
                        walking_bit <= 4'd0;
                        phase <= PH_WALK_RD;
                        progress <= PH_WALK_RD;
                        begin_operation(1'b0, 25'h0000100);
                    end else begin
                        walking_bit <= walking_bit + 1'b1;
                        begin_operation(1'b1, 25'h0000100 +
                                        ({21'd0, walking_bit} + 1'b1) * 8);
                    end
                end

                PH_WALK_RD: if (operation_state == OP_WAIT && cmd_done) begin
                    if (walking_bit == 15) begin
                        burst_number <= 32'd0;
                        phase <= PH_FULL_WR;
                        progress <= PH_FULL_WR;
                        begin_operation(1'b1, 25'd0);
                    end else begin
                        walking_bit <= walking_bit + 1'b1;
                        begin_operation(1'b0, 25'h0000100 +
                                        ({21'd0, walking_bit} + 1'b1) * 8);
                    end
                end

                PH_FULL_WR: if (operation_state == OP_WAIT && cmd_done) begin
                    if (burst_number == TOTAL_BURSTS - 1) begin
                        burst_number <= 32'd0;
                        phase <= PH_FULL_RD;
                        progress <= PH_FULL_RD;
                        begin_operation(1'b0, 25'd0);
                    end else begin
                        burst_number <= burst_number + 1'b1;
                        begin_operation(1'b1, (burst_number + 1'b1) << 3);
                    end
                end

                PH_FULL_RD: if (operation_state == OP_WAIT && cmd_done) begin
                    if (burst_number == TOTAL_BURSTS - 1) begin
                        phase <= PH_DONE;
                        progress <= PH_DONE;
                        done <= 1'b1;
                        pass <= (error_count == 0);
                        fail <= (error_count != 0);
                    end else begin
                        burst_number <= burst_number + 1'b1;
                        begin_operation(1'b0, (burst_number + 1'b1) << 3);
                    end
                end

                default: begin
                    cmd_valid <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule
