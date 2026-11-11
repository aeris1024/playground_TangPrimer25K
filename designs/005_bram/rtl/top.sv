module top #(
    parameter integer ADDR_WIDTH = 10,
    parameter integer DATA_WIDTH = 16
) (
    input  wire clk,
    output wire led_ready,
    output wire led_done
);
    localparam [2:0] WRITE = 3'd0, READ_WAIT = 3'd1, READ_CHECK = 3'd2,
                     PASS = 3'd3, FAIL = 3'd4;

    reg [2:0] state = WRITE;
    reg [ADDR_WIDTH-1:0] address = {ADDR_WIDTH{1'b0}};
    wire [DATA_WIDTH-1:0] read_data;
    wire write_enable = (state == WRITE);
    wire [DATA_WIDTH-1:0] test_pattern =
        {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, address} ^ 16'ha5a5;
    wire last_address = &address;

    single_port_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ram (
        .clk(clk),
        .write_enable(write_enable),
        .address(address),
        .write_data(test_pattern),
        .read_data(read_data)
    );

    always @(posedge clk) begin
        case (state)
            WRITE: begin
                if (last_address) begin
                    address <= {ADDR_WIDTH{1'b0}};
                    state <= READ_WAIT;
                end else begin
                    address <= address + 1'b1;
                end
            end
            READ_WAIT: state <= READ_CHECK;
            READ_CHECK: begin
                if (read_data !== test_pattern) begin
                    state <= FAIL;
                end else if (last_address) begin
                    state <= PASS;
                end else begin
                    address <= address + 1'b1;
                    state <= READ_WAIT;
                end
            end
            default: state <= state;
        endcase
    end

    assign led_ready = (state == PASS);
    assign led_done = (state == FAIL);
endmodule
