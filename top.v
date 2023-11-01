`include "clockworks.v"

module SOC (
    input clk_12M,
    input rst,
    output [2:0] leds
);

    reg [2:0] MEM [0:20];
    initial begin
        MEM[0] = 3'b000;
        MEM[1] = 3'b001;
        MEM[2] = 3'b010;
        MEM[3] = 3'b000;
        MEM[4] = 3'b001;
        MEM[5] = 3'b010;
        MEM[6] = 3'b000;
        MEM[7] = 3'b001;
        MEM[8] = 3'b010;
        MEM[9] = 3'b000;
        MEM[10] = 3'b001;
        MEM[11] = 3'b010;
        MEM[12] = 3'b000;
        MEM[13] = 3'b001;
        MEM[14] = 3'b010;
        MEM[15] = 3'b000;
        MEM[16] = 3'b001;
        MEM[17] = 3'b010;
        MEM[18] = 3'b000;
        MEM[19] = 3'b001;
        MEM[20] = 3'b010;
    end

    reg [4:0] PC = 0;
    wire clk;
    wire rst_n;

    Clockworks #(
        .SLOW(23)
    ) CW (
        .CLK(clk_12M),
        .RESET(rst),
        .clk(clk),
        .rst_n(rst_n)
    );

    always @(posedge clk) begin
        leds <= MEM[PC];
        PC = (PC == 20) ? 0 : PC + 1;
    end

endmodule
