module SOC (
    input clk_12M,
    input rst,
    output led_green,
    output led_red,
    output led_blue,
);

    reg [24:0] counter;

    always @(posedge clk_12M)
    begin
        counter <= counter + 1;
    end

    assign led_green = counter[13];
    assign led_red = counter[22];
    assign led_blue = counter[21];


    
endmodule
