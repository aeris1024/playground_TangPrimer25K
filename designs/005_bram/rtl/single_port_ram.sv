module single_port_ram #(
    parameter integer ADDR_WIDTH = 10,
    parameter integer DATA_WIDTH = 16
) (
    input  wire                  clk,
    input  wire                  write_enable,
    input  wire [ADDR_WIDTH-1:0] address,
    input  wire [DATA_WIDTH-1:0] write_data,
    output reg  [DATA_WIDTH-1:0] read_data
);
    (* syn_ramstyle = "block_ram" *)
    reg [DATA_WIDTH-1:0] memory [0:(1 << ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= write_data;
        read_data <= memory[address];
    end
endmodule
