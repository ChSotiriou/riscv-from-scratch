`include "clockworks.v"

module SOC (
    input CLK_12M,
    input RESET,
    output [4:0] LEDS,
    output STATUS
);
    reg [31:0] MEM [0:255];
    reg [31:0] PC;

    `include "riscv_assembly.v"
    integer L0_ = 8;
    integer L1_ = 16;
    initial begin
        PC = 0;
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

    reg [31:0] RegisterBank [0:31];
    reg [31:0] rs1;
    reg [31:0] rs2;

`ifdef BENCH   
    integer i;
    initial begin
        for(i=0; i<32; ++i) begin
            RegisterBank[i] = 0;
        end
    end
`endif   

    //////////////////////////////////////////////////////////////
    // Instruction Decoder
    //////////////////////////////////////////////////////////////
    reg [31:0] instr = 0;

    // Decode Instruction Type
    wire isALUreg   =   (instr[6:0] == 7'b0110011);
    wire isALUimm   =   (instr[6:0] == 7'b0010011);
    wire isBranch   =   (instr[6:0] == 7'b1100011);
    wire isJALR     =   (instr[6:0] == 7'b1100111);
    wire isJAL      =   (instr[6:0] == 7'b1101111);
    wire isAUIPC    =   (instr[6:0] == 7'b0010111);
    wire isLUI      =   (instr[6:0] == 7'b0110111);
    wire isLoad     =   (instr[6:0] == 7'b0000011);
    wire isStore    =   (instr[6:0] == 7'b0100011);
    wire isSYSTEM   =   (instr[6:0] == 7'b1110011);

    // Function Codes
    wire [2:0] funct3   =   instr[14:12];
    wire [6:0] funct7   =   instr[31:25];

    // R-Type Instructions
    wire [4:0] rs1Id    =   instr[19:15];
    wire [4:0] rs2Id    =   instr[24:20];
    wire [4:0] rdId     =   instr[11:7];
    
    // Immediate Values
    wire [31:0] Iimm    =   { {21{instr[31]}} , instr[30:20] }; // I-Type
    wire [31:0] Simm    =   { {21{instr[31]}} , instr[30:25] , instr[11:7]}; // S-Type
    wire [31:0] Bimm    =   { {20{instr[31]}} , instr[7], instr[30:25] , instr[11:8], 1'b0}; // B-Type
    wire [31:0] Uimm    =   { instr[31:12] , 12'b0}; // U-Type
    wire [31:0] Jimm    =   { {12{instr[31]}} , instr[19:12] , instr[20] , instr[30:21] , 1'b0}; // J-Type

    //////////////////////////////////////////////////////////////
    // State Machine
    //////////////////////////////////////////////////////////////
    localparam FETCH_INSTR = 0;
    localparam FETCH_REGS = 1;
    localparam EXECUTE = 2;
    reg [1:0] state = FETCH_INSTR;
    wire [31:0] nextPC =    isJAL                   ? PC + Jimm :
                            isJALR                  ? PC + Iimm :
                            isBranch && takeBranch  ? PC + Bimm : 
                            PC + 4;

    always @(posedge clk) begin
        case (state)
            FETCH_INSTR: begin
                if (!rst_n) begin
                    PC <= 0;
                end else begin
                    instr <= MEM[PC[31:2]];
                    state <= FETCH_REGS;
                end
            end
            FETCH_REGS: begin
                rs1 <= RegisterBank[rs1Id];
                rs2 <= RegisterBank[rs2Id];
                state <= EXECUTE;
            end
            EXECUTE: begin
                if (!isSYSTEM) begin
                    PC <= nextPC;
                end
                state <= FETCH_INSTR;
            end
        endcase
    end

    wire [31:0] writeBackData;
    wire writeBackEnable;
    always @(posedge clk) begin
        if (writeBackEnable && rdId != 0) begin
`ifdef BENCH	 
            $display("x%0d <= 0x%0x",rdId,writeBackData);
`endif	 
            RegisterBank[rdId] <= writeBackData;
        end
    end

`ifdef BENCH
    always @(posedge clk ) begin
        if (state == FETCH_INSTR) begin
            case (1'b1)
            isALUreg : $display("ALUreg rd=x%0d rs1=x%0d rs2=x%0d funct3=%b", rdId, rs1Id, rs2Id, funct3);
            isALUimm : $display("ALUimm rd=x%0d rs1=x%0d imm=0x%0x funct3=%b", rdId, rs1Id, Iimm, funct3);
            isBranch : $display("BRANCH");
            isJALR   : $display("JALR");
            isJAL    : $display("JAL");
            isAUIPC  : $display("ALUAUIPC");
            isLUI    : $display("LUI");
            isLoad   : $display("LOAD");
            isStore  : $display("STORE");
            isSYSTEM : begin 
                $display("SYSTEM");
                $finish();
            end
            endcase
        end
    end
`endif

    //////////////////////////////////////////////////////////////
    // ALU
    //////////////////////////////////////////////////////////////
    wire [31:0] aluIn1 = rs1;
    wire [31:0] aluIn2 = isALUreg ? rs2 : Iimm;
    reg [31:0] aluOut;
    wire [4:0] shamt = isALUreg ? rs2[4:0] : instr[24:20];
    always @(*) begin
        case (funct3)
        3'b000: aluOut = (funct7[5] & isALUreg) ? (aluIn1 - aluIn2) : (aluIn1 + aluIn2);
        3'b001: aluOut = (aluIn1 << shamt);
        3'b010: aluOut = ($signed(aluIn1) < $signed(aluIn2)); 
        3'b011: aluOut = (aluIn1 < aluIn2);
        3'b100: aluOut = (aluIn1 ^ aluIn2);
        3'b101: aluOut = funct7[5] ? ($signed(aluIn1) >>> shamt) : (aluIn1 >> shamt); 
        3'b110: aluOut = (aluIn1 | aluIn2); 
        3'b111: aluOut = (aluIn1 & aluIn2);
        endcase
    end

    assign writeBackData =  (isJAL || isJALR)   ?   (PC + 4) :
                            isLUI               ?   Uimm :
                            isAUIPC             ?   PC + Uimm :
                                                    aluOut;
    assign writeBackEnable = (state == EXECUTE && (isALUimm || isALUreg || isJAL || isJALR || isLUI || isAUIPC));

`ifdef BENCH
    always @(posedge clk) begin
        if (state == EXECUTE && (isALUimm || isALUreg)) begin
            case (funct3)
            3'b000: $display("0x%0x %s 0x%0x = 0x%0x", aluIn1, (funct7[5] & isALUreg) ? "-":"+", aluIn2, aluOut);
            3'b001: $display("0x%0x << 0x%0x = 0x%0x", aluIn1, shamt, aluOut);
            3'b010: $display("0x%0x < 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
            3'b011: $display("0x%0x < 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
            3'b100: $display("0x%0x ^ 1x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
            3'b101: $display("ALU Shift Right");
            3'b110: $display("0x%0x | 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
            3'b111: $display("0x%0x & 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
            endcase
        end
    end
`endif

    //////////////////////////////////////////////////////////////
    // Branch
    //////////////////////////////////////////////////////////////
    reg takeBranch;
    always @(*) begin
        case (funct3) 
        3'b000: takeBranch = (rs1 == rs2);
        3'b001: takeBranch = (rs1 != rs2);
        3'b100: takeBranch = ($signed(rs1) < $signed(rs2));
        3'b101: takeBranch = ($signed(rs1) >= $signed(rs2)); 
        3'b110: takeBranch = (rs1 < rs2); 
        3'b111: takeBranch = (rs1 >= rs2); 
        default: takeBranch = 1'b1;
        endcase
    end

    wire clk;
    wire rst_n;

        Clockworks #(
    `ifdef BENCH
            .SLOW(14)
    `else
            .SLOW(19)
    `endif
        ) CW (
            .CLK(CLK_12M),
            .RESET(RESET),
            .clk(clk),
            .rst_n(rst_n)
        );

    assign LEDS = RegisterBank[1][5:0];
    assign STATUS = (state == FETCH_INSTR || isSYSTEM);

endmodule
