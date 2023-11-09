module Memory (
    input               clk,
    input       [31:0]  mem_addr,
    input               mem_rstrb,
    output reg  [31:0]  mem_rdata
);

    reg [31:0] MEM [0:255];

`include "riscv_assembly.v"
    integer L0_ = 4;
    integer F_WAIT_ = 32;
    integer WAIT_ = 40;
    initial begin
        ADD(x2, x0, x0);
    Label(L0_);
        ADDI(x2, x0, 1);

        ADDI(x10, x0, 10);
        JAL(x1, LabelRef(F_WAIT_));

        ADDI(x2, x0, 0);

        ADDI(x10, x0, 15);
        JAL(x1, LabelRef(F_WAIT_));

        JAL(x0, LabelRef(L0_));

    Label(F_WAIT_);
        ADD(x5, x0, 1);
        SLL(x5, x5, x10);
    Label(WAIT_);
        ADDI(x5, x5, -1);
        BNE(x5, x0, LabelRef(WAIT_));
        JALR(x0, x1, 0);

        EBREAK();
        endASM();
    end	   

    always @(posedge clk) begin
        if (mem_rstrb) begin
            mem_rdata <= MEM[mem_addr[31:2]];
        end
    end

endmodule