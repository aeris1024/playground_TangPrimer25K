module burst_uart_reporter (
    input  wire         clk,
    input  wire         reset,
    input  wire         test_done,
    input  wire         test_pass,
    input  wire [127:0] read_words,
    input  wire         uart_busy,
    output wire         uart_start,
    output wire [7:0]   uart_data,
    output reg          report_done
);
    localparam integer MESSAGE_LENGTH = 76;

    reg sending = 1'b0;
    reg [6:0] position = 7'd0;
    reg result_pass = 1'b0;
    reg [127:0] result_words = 128'd0;

    assign uart_start = sending && !uart_busy;
    assign uart_data = message_byte(position, result_pass, result_words);

    function automatic [7:0] hex_digit(input [3:0] value);
        begin
            hex_digit = value < 10 ? "0" + value : "A" + value - 10;
        end
    endfunction

    function automatic [7:0] message_byte(
        input [6:0] index,
        input pass_value,
        input [127:0] words
    );
        integer offset;
        integer word_index;
        integer digit_index;
        reg [15:0] selected_word;
        begin
            if (index >= 35 && index <= 73) begin
                offset = index - 35;
                word_index = offset / 5;
                digit_index = offset % 5;
                if (digit_index == 4) begin
                    message_byte = " ";
                end else begin
                    case (word_index)
                        0: selected_word = words[15:0];
                        1: selected_word = words[31:16];
                        2: selected_word = words[47:32];
                        3: selected_word = words[63:48];
                        4: selected_word = words[79:64];
                        5: selected_word = words[95:80];
                        6: selected_word = words[111:96];
                        default: selected_word = words[127:112];
                    endcase
                    case (digit_index)
                        0: message_byte = hex_digit(selected_word[15:12]);
                        1: message_byte = hex_digit(selected_word[11:8]);
                        2: message_byte = hex_digit(selected_word[7:4]);
                        default: message_byte = hex_digit(selected_word[3:0]);
                    endcase
                end
            end else begin
                case (index)
                    0: message_byte = "T";  1: message_byte = "E";
                    2: message_byte = "S";  3: message_byte = "T";
                    4: message_byte = " ";  5: message_byte = "0";
                    6: message_byte = "0";  7: message_byte = "8";
                    8: message_byte = "_";  9: message_byte = "s";
                    10: message_byte = "d"; 11: message_byte = "r";
                    12: message_byte = "a"; 13: message_byte = "m";
                    14: message_byte = "_"; 15: message_byte = "b";
                    16: message_byte = "u"; 17: message_byte = "r";
                    18: message_byte = "s"; 19: message_byte = "t";
                    20: message_byte = " "; 21: message_byte = ".";
                    22: message_byte = "."; 23: message_byte = ".";
                    24: message_byte = " ";
                    25: message_byte = pass_value ? "P" : "F";
                    26: message_byte = pass_value ? "A" : "A";
                    27: message_byte = pass_value ? "S" : "I";
                    28: message_byte = pass_value ? "S" : "L";
                    29: message_byte = " "; 30: message_byte = "r";
                    31: message_byte = "e"; 32: message_byte = "a";
                    33: message_byte = "d"; 34: message_byte = "=";
                    74: message_byte = 8'h0d;
                    default: message_byte = 8'h0a;
                endcase
            end
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            sending <= 1'b0;
            position <= 7'd0;
            report_done <= 1'b0;
        end else begin
            if (test_done && !sending && !report_done) begin
                result_pass <= test_pass;
                result_words <= read_words;
                position <= 7'd0;
                sending <= 1'b1;
            end else if (uart_start) begin
                if (position == MESSAGE_LENGTH - 1) begin
                    sending <= 1'b0;
                    report_done <= 1'b1;
                end else begin
                    position <= position + 1'b1;
                end
            end
        end
    end
endmodule
