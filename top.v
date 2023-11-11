`include "clockworks.v"
`include "memory.v"
`include "processor.v"
`include "peripheralGPIO.v"

module SOC (
    input CLK_12M,
    input RESET,
    output [4:0] LEDS,
    output STATUS
);
    localparam MMIO_GPIO_BIT = 0;

    wire clk;
    wire rst_n;

    wire [31:0] GPIO0;

    wire [31:0] mem_addr;
    wire mem_rstrb;
    wire [31:0] mem_rdata;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wmask;

    wire [31:0] debug;

    wire [29:0] mem_wordaddr = mem_addr[31:2];
    wire isIO = mem_addr[22];
    wire isRAM = !isIO;

    wire mem_wstrb = |mem_wmask;

    Memory RAM (
        .clk(clk),
        .mem_addr(mem_addr),
        .mem_rstrb(isRAM & mem_rstrb),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_wmask({4{isRAM}} & mem_wmask)
    );

    PeripheralGPIO GPIO0_M (
        .clk(clk),
        .IO(GPIO0),
        .mem_wstrb(isIO & mem_wordaddr[MMIO_GPIO_BIT] & mem_wstrb),
        .mem_wdata(mem_wdata)
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

    assign LEDS = GPIO0[4:0];

endmodule
