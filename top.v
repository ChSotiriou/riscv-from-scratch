`include "clockworks.v"

module SOC (
    input clk_12M,
    input rst,
    output [4:0] leds
);
    reg [31:0] MEM [0:7];
    initial begin
        // add x1, x0, x0
        //                    rs2   rs1  add  rd  ALUREG
        MEM[0] = 32'b0000000_00000_00000_000_00001_0110011;

        // addi x1, x1, 1
        //             imm         rs1  add  rd   ALUIMM
        MEM[1] = 32'b000000000001_00001_000_00001_0010011;
        
        // add x1, x0, x0
        //                    rs2   rs1  add  rd  ALUREG
        MEM[2] = 32'b0000000_00000_00000_000_00001_0110011;

        // lw x2,0(x1)
        //             imm         rs1   w   rd   LOAD
        MEM[3] = 32'b000000000000_00001_010_00010_0000011;

        // addi x1, x1, 1
        //             imm         rs1  add  rd   ALUIMM
        MEM[4] = 32'b000000000001_00001_000_00001_0010011;


        // lw x2,0(x1)
        //             imm         rs1   w   rd   LOAD
        MEM[5] = 32'b000000000000_00001_010_00010_0000011;
        // sw x2,0(x1)
        //             imm   rs2   rs1   w   imm  STORE
        MEM[6] = 32'b000000_00001_00010_010_00000_0100011;
        // ebreak
        //                                        SYSTEM
        MEM[7] = 32'b000000000001_00000_000_00000_1110011;
    end	   

    reg [31:0] RegisterBank [0:31];
    reg [31:0] rs1;
    reg [31:0] rs2;

    // instruction decoder
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
    reg [4:0] PC = 0;
    localparam FETCH_INSTR = 0;
    localparam FETCH_REGS = 1;
    localparam EXECUTE = 2;
    reg [1:0] state = FETCH_INSTR;

    always @(posedge clk) begin
        case (state)
            FETCH_INSTR: begin
                instr <= MEM[PC];
                state <= FETCH_REGS;
            end
            FETCH_REGS: begin
                rs1 <= RegisterBank[rs1Id];
                rs2 <= RegisterBank[rs2Id];
                state <= EXECUTE;
            end
            EXECUTE: begin
                if (!isSYSTEM) begin
                    PC <= PC + 1;
                end
                state <= FETCH_INSTR;
            end
        endcase
    end

    wire [31:0] writeBackData = 0;
    wire writeBackEnable = 0;
    always @(posedge clk) begin
        if (writeBackEnable && rdId != 0) begin
            RegisterBank[rdId] <= writeBackData;
        end
    end

    // synchronous reset
    always @(posedge clk) begin
        if (!rst_n) begin
            PC <= 0;
            state <= FETCH_INSTR;
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

    assign writeBackData = aluOut;
    assign writeBackEnable = (state == EXECUTE && (isALUimm || isALUreg));

    wire clk;
    wire rst_n;

        Clockworks #(
    `ifdef BENCH
            .SLOW(1)
    `else
            .SLOW(21)
    `endif
        ) CW (
            .CLK(clk_12M),
            .RESET(rst),
            .clk(clk),
            .rst_n(rst_n)
        );



    assign leds = isSYSTEM ? 31 : {PC[0], PC[1], state, 1'b0};

endmodule
