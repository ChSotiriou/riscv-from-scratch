module Memory (
    input               clk,
    input       [31:0]  mem_addr,
    input               mem_rstrb,
    output reg  [31:0]  mem_rdata
);

    reg [31:0] MEM [0:255];

`include "riscv_assembly.v"
    integer L0_ = 4;
    integer F_WAIT_ = 40;
    integer WAIT_ = 48;
    integer F_MULT_ = 60;
    integer MULT_ = 68;
    initial begin
        LI(gp, 1);
    Label(L0_);
        LI(a0, 15);
        CALL(LabelRef(F_WAIT_));

        MV(a0, gp);
        LI(a1, 3);
        CALL(LabelRef(F_MULT_));
        MV(gp, a0);

        J(LabelRef(L0_));

    Label(F_WAIT_);
        LI(t0, 1);
        SLL(t0, t0, a0);
    Label(WAIT_);
        ADDI(t0, t0, -1);
        BNEZ(t0, LabelRef(WAIT_));
        RET();

    Label(F_MULT_);
        MV(t0, a0);
        LI(a0, 0);
    Label(MULT_);
        ADD(a0, a0, t0);
        ADDI(a1, a1, -1);
        BNEZ(a1, LabelRef(MULT_));
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