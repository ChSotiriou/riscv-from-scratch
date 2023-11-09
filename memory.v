module Memory (
    input               clk,
    input       [31:0]  mem_addr,
    input               mem_rstrb,
    output reg  [31:0]  mem_rdata
);

    reg [31:0] MEM [0:255];

`include "riscv_assembly.v"
    integer L0_ = 0;
    integer F_WAIT_ = 36;
    integer WAIT_ = 44;
    initial begin
    Label(L0_);
        LI(gp, 1);

        LI(a0, 11);
        CALL(LabelRef(F_WAIT_));

        LI(gp, 0);

        LI(a0, 17);
        CALL(LabelRef(F_WAIT_));

        J(LabelRef(L0_));

    Label(F_WAIT_);
        LI(t0, 1);
        SLL(t0, t0, a0);
    Label(WAIT_);
        ADDI(t0, t0, -1);
        BNEZ(t0, LabelRef(WAIT_));
        RET();

        EBREAK();
        endASM();
    end	   

    always @(posedge clk) begin
        if (mem_rstrb) begin
            mem_rdata <= MEM[mem_addr[31:2]];
        end
    end

endmodule