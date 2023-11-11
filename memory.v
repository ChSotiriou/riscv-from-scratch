module Memory (
    input               clk,
    input       [31:0]  mem_addr,
    input               mem_rstrb,
    output reg  [31:0]  mem_rdata,
    input       [31:0]  mem_wdata,
    input       [3:0]   mem_wmask
);

    reg [31:0] MEM [0:255];

`include "riscv_assembly.v"
    integer L0_ = 8;
    integer L1_ = 32;
    integer F_WAIT_ = 64;
    integer WAIT_ = 72;
    integer F_MULT_ = 48;
    integer MULT_ = 56;
    initial begin
        LI(s0, 0);
        LI(s1, 17);
    Label(L0_);
        SB(s0, s0, 400);
        ADDI(s0, s0, 1);
        ADDI(s1, s1, -1);
        BNEZ(s1, LabelRef(L0_));

        LI(s0, 0);
        LI(s1, 17);
    Label(L1_);
        LB(gp, s0, 400);
        ADDI(s0, s0, 1);

        LI(a0, 18);
        CALL(LabelRef(F_WAIT_));

        ADDI(s1, s1, -1);
        BNEZ(s1, LabelRef(L1_));

        EBREAK();

    Label(F_WAIT_);
        LI(t0, 1);
        SLL(t0, t0, a0);
    Label(WAIT_);
        ADDI(t0, t0, -1);
        BNEZ(t0, LabelRef(WAIT_));
        RET();

    // Label(F_MULT_);
    //     MV(t0, a0);
    //     LI(a0, 0);
    // Label(MULT_);
    //     ADD(a0, a0, t0);
    //     ADDI(a1, a1, -1);
    //     BNEZ(a1, LabelRef(MULT_));
    //     RET();

        endASM();

        // MEM[100] = {8'h4, 8'h3, 8'h2, 8'h1};
        // MEM[101] = {8'h8, 8'h7, 8'h6, 8'h5};
        // MEM[102] = {8'hc, 8'hb, 8'ha, 8'h9};
        // MEM[103] = {8'hff, 8'hf, 8'he, 8'hd};  
    end	   


    wire [29:0] word_addr = mem_addr[31:2]; 
    always @(posedge clk) begin
        if (mem_rstrb) begin
            mem_rdata <= MEM[word_addr];
        end
        if (mem_wmask[0]) MEM[word_addr][7:0]   <= mem_wdata[7:0];
        if (mem_wmask[1]) MEM[word_addr][15:8]  <= mem_wdata[15:8];
        if (mem_wmask[2]) MEM[word_addr][23:16] <= mem_wdata[23:16];
        if (mem_wmask[3]) MEM[word_addr][31:24] <= mem_wdata[31:24];
    end

endmodule