`include "clockworks.v"

module SOC (
    input clk_12M,
    input rst,
    output [4:0] leds
);

    reg [4:0] MEM [0:20];
    initial begin
        MEM[0] = 5'b00000;
        MEM[1] = 5'b11111;
        MEM[2] = 5'b10101;
        MEM[3] = 5'b01010;
        MEM[4] = 5'b00001;
        MEM[5] = 5'b00010;
        MEM[6] = 5'b00011;
        MEM[7] = 5'b00100;
        MEM[8] = 5'b00101;
        MEM[9] = 5'b00110;
        MEM[10] = 5'b00111;
        MEM[11] = 5'b10000;
        MEM[12] = 5'b01000;
        MEM[13] = 5'b00100;
        MEM[14] = 5'b00010;
        MEM[15] = 5'b00001;
        MEM[16] = 5'b00010;
        MEM[17] = 5'b00100;
        MEM[18] = 5'b01000;
        MEM[19] = 5'b10000;
        MEM[20] = 5'b11111;
    end

    reg [4:0] PC = 0;
    wire clk;
    wire rst_n;

    Clockworks #(
        .SLOW(22)
    ) CW (
        .CLK(clk_12M),
        .RESET(rst),
        .clk(clk),
        .rst_n(rst_n)
    );

    assign rst_n = rst;

    always @(posedge clk) begin
        leds <= MEM[PC];
        PC = (!rst_n || PC == 20) ? 0 : PC + 1;
    end

endmodule
