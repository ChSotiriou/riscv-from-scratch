module Memory (
    input               clk,
    input       [31:0]  mem_addr,
    input               mem_rstrb,
    output reg  [31:0]  mem_rdata
);

    reg [31:0] MEM [0:255];

`include "riscv_assembly.v"
    integer L0_ = 8;
    initial begin
        ADD(x1, x0, x0);
        ADDI(x2, x0, 10);
    Label(L0_);
        ADDI(x1, x1, 1);
        BLT(x1, x2, LabelRef(L0_));

        ADD(x1, x0, x0);
        JAL(x0, LabelRef(L0_));

        EBREAK();
        endASM();
    end	   

    always @(posedge clk) begin
        if (mem_rstrb) begin
            mem_rdata <= MEM[mem_addr[31:2]];
        end
    end

endmodule