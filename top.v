`include "clockworks.v"
`include "memory.v"
`include "processor.v"

module SOC (
    input CLK_12M,
    input RESET,
    output [4:0] LEDS,
    output STATUS
);
    wire clk;
    wire rst_n;

    wire [31:0] mem_addr;
    wire mem_rstrb;
    wire [31:0] mem_rdata;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wmask;

    wire [31:0] debug;

    Memory RAM (
        .clk(clk),
        .mem_addr(mem_addr),
        .mem_rstrb(mem_rstrb),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_wmask(mem_wmask)
    );

    Processor CPU (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata),
        .mem_rstrb(mem_rstrb),
        .mem_wdata(mem_wdata),
        .mem_wmask(mem_wmask),
        .debug(debug),
        .status(STATUS)
    );


    Clockworks CW (
        .CLK(CLK_12M),
        .RESET(RESET),
        .clk(clk),
        .rst_n(rst_n)
    );

    assign LEDS = debug[4:0];

endmodule
