`include "clockworks.v"

module SOC (
    input clk_12M,
    input rst,
    output led_green,
    output led_red,
    output led_blue
);

    wire clk;
    wire rst_n;

    reg [3:0] count = 0;
    always @(posedge clk)
    begin
        count <= count + 1;
    end

    assign led_green = count[0];
    assign led_red = count[1];
    assign led_blue = count[2];

    Clockworks #(
        .SLOW(18)
    ) CW (
        .CLK(clk_12M),
        .RESET(rst),
        .clk(clk),
        .rst_n(rst_n)
    );
    
endmodule
