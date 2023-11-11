module PeripheralGPIO (
    input               clk,
    output reg [31:0]   IO,
    input               mem_wstrb,
    input      [31:0]   mem_wdata
);

always @(posedge clk) begin
    if (mem_wstrb) begin
        `ifdef BENCH
            $display("THING");
        `endif  
        IO <= mem_wdata;
    end
end

endmodule