module bist_uart_reporter (
    input  wire        clk,
    input  wire        reset,
    input  wire        bist_done,
    input  wire        bist_pass,
    input  wire [31:0] error_count,
    input  wire [24:0] first_error_address,
    input  wire        uart_busy,
    output wire        uart_start,
    output wire [7:0]  uart_data,
    output reg         report_done
);
    reg sending = 1'b0;
    reg [5:0] position = 6'd0;
    reg result_pass = 1'b0;
    reg [31:0] result_errors = 32'd0;
    reg [24:0] result_first = 25'd0;

    assign uart_start = sending && !uart_busy;
    assign uart_data = message_byte(position, result_pass, result_errors, result_first);

    function automatic [7:0] hex_digit(input [3:0] value);
        begin
            hex_digit = value < 10 ? "0" + value : "A" + value - 10;
        end
    endfunction

    function automatic [7:0] message_byte(
        input [5:0] index,
        input pass_value,
        input [31:0] errors,
        input [24:0] first_address
    );
        begin
            case (index)
                0: message_byte = "T";  1: message_byte = "E";
                2: message_byte = "S";  3: message_byte = "T";
                4: message_byte = " ";  5: message_byte = "0";
                6: message_byte = "0";  7: message_byte = "9";
                8: message_byte = "_";  9: message_byte = "s";
                10: message_byte = "d"; 11: message_byte = "r";
                12: message_byte = "a"; 13: message_byte = "m";
                14: message_byte = "_"; 15: message_byte = "u";
                16: message_byte = "a"; 17: message_byte = "r";
                18: message_byte = "t"; 19: message_byte = " ";
                20: message_byte = "."; 21: message_byte = ".";
                22: message_byte = "."; 23: message_byte = " ";
                24: message_byte = pass_value ? "P" : "F";
                25: message_byte = pass_value ? "A" : "A";
                26: message_byte = pass_value ? "S" : "I";
                27: message_byte = pass_value ? "S" : "L";
                28: message_byte = " "; 29: message_byte = "e";
                30: message_byte = "r"; 31: message_byte = "r";
                32: message_byte = "o"; 33: message_byte = "r";
                34: message_byte = "s"; 35: message_byte = "=";
                36: message_byte = "0"; 37: message_byte = "x";
                38: message_byte = hex_digit(errors[31:28]);
                39: message_byte = hex_digit(errors[27:24]);
                40: message_byte = hex_digit(errors[23:20]);
                41: message_byte = hex_digit(errors[19:16]);
                42: message_byte = hex_digit(errors[15:12]);
                43: message_byte = hex_digit(errors[11:8]);
                44: message_byte = hex_digit(errors[7:4]);
                45: message_byte = hex_digit(errors[3:0]);
                46: message_byte = " "; 47: message_byte = "f";
                48: message_byte = "i"; 49: message_byte = "r";
                50: message_byte = "s"; 51: message_byte = "t";
                52: message_byte = "="; 53: message_byte = "0";
                54: message_byte = "x";
                55: message_byte = hex_digit({3'b000, first_address[24]});
                56: message_byte = hex_digit(first_address[23:20]);
                57: message_byte = hex_digit(first_address[19:16]);
                58: message_byte = hex_digit(first_address[15:12]);
                59: message_byte = hex_digit(first_address[11:8]);
                60: message_byte = hex_digit(first_address[7:4]);
                61: message_byte = hex_digit(first_address[3:0]);
                62: message_byte = 8'h0d;
                default: message_byte = 8'h0a;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            sending <= 1'b0;
            position <= 6'd0;
            report_done <= 1'b0;
        end else begin
            if (bist_done && !sending && !report_done) begin
                result_pass <= bist_pass;
                result_errors <= error_count;
                result_first <= first_error_address;
                position <= 6'd0;
                sending <= 1'b1;
            end else if (uart_start) begin
                if (position == 63) begin
                    sending <= 1'b0;
                    report_done <= 1'b1;
                end else begin
                    position <= position + 1'b1;
                end
            end
        end
    end
endmodule
