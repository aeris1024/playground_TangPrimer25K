module top #(
    parameter integer CLOCK_HZ = 50_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer REPEAT_CYCLES = 50_000_000
) (
    input  wire clk,
    output wire uart_tx_pin
);
    localparam integer MESSAGE_LENGTH = 14;
    localparam integer GAP_WIDTH =
        (REPEAT_CYCLES <= 1) ? 1 : $clog2(REPEAT_CYCLES);
    localparam [1:0] START = 2'd0, WAIT_BUSY = 2'd1, WAIT_DONE = 2'd2, GAP = 2'd3;

    reg [1:0] state = START;
    reg [3:0] message_index = 4'd0;
    reg [GAP_WIDTH-1:0] gap_count = {GAP_WIDTH{1'b0}};
    reg tx_start = 1'b0;
    reg [7:0] tx_data = 8'h00;
    wire tx_busy;

    function automatic [7:0] message_byte(input [3:0] index);
        case (index)
            4'd0:  message_byte = "F";
            4'd1:  message_byte = "P";
            4'd2:  message_byte = "G";
            4'd3:  message_byte = "A";
            4'd4:  message_byte = " ";
            4'd5:  message_byte = "U";
            4'd6:  message_byte = "A";
            4'd7:  message_byte = "R";
            4'd8:  message_byte = "T";
            4'd9:  message_byte = " ";
            4'd10: message_byte = "T";
            4'd11: message_byte = "X";
            4'd12: message_byte = 8'h0d;
            default: message_byte = 8'h0a;
        endcase
    endfunction

    uart_tx #(
        .CLOCK_HZ(CLOCK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) transmitter (
        .clk(clk),
        .start(tx_start),
        .data(tx_data),
        .tx(uart_tx_pin),
        .busy(tx_busy)
    );

    always @(posedge clk) begin
        tx_start <= 1'b0;
        case (state)
            START: begin
                tx_data <= message_byte(message_index);
                tx_start <= 1'b1;
                state <= WAIT_BUSY;
            end
            WAIT_BUSY: begin
                if (tx_busy)
                    state <= WAIT_DONE;
            end
            WAIT_DONE: begin
                if (!tx_busy) begin
                    if (message_index == MESSAGE_LENGTH - 1) begin
                        message_index <= 4'd0;
                        gap_count <= {GAP_WIDTH{1'b0}};
                        state <= GAP;
                    end else begin
                        message_index <= message_index + 1'b1;
                        state <= START;
                    end
                end
            end
            default: begin
                if (gap_count == REPEAT_CYCLES - 1)
                    state <= START;
                else
                    gap_count <= gap_count + 1'b1;
            end
        endcase
    end
endmodule
