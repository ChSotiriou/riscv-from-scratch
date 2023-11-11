module Processor (
    input               clk,
    input               rst_n,
    output      [31:0]  mem_addr,
    input       [31:0]  mem_rdata,
    output              mem_rstrb,
    output      [31:0]  mem_wdata,
    output      [3:0]   mem_wmask,
    output      [31:0]  debug,      // used for the LEDS for debugging
    output              status      // used for the STATUS LED for debugging
);
    reg [31:0] PC = 0;
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
    localparam WAIT_INSTR = 1;
    localparam FETCH_REGS = 2;
    localparam EXECUTE = 3;
    localparam LOAD = 4;
    localparam WAIT_DATA = 5;
    localparam STORE = 6;
    reg [2:0] state = FETCH_INSTR;
    wire [31:0] nextPC =    isJAL                   ? PC + Jimm :
                            isJALR                  ? rs1 + Iimm :
                            isBranch && takeBranch  ? PC + Bimm : 
                            PC + 4;

    assign mem_addr = (state == WAIT_INSTR || state == FETCH_INSTR) ? PC : loadstore_addr;
    assign mem_rstrb = (state == FETCH_INSTR || state == LOAD);
    assign mem_wmask = ({4{state == STORE}} & store_wmask);

    always @(posedge clk) begin
        case (state)
            FETCH_INSTR: begin
                if (!rst_n) begin
                    PC <= 0;
                end else begin
                    state <= WAIT_INSTR;
                end
            end
            WAIT_INSTR: begin
                instr <= mem_rdata;
                state <= FETCH_REGS;
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
                state <= isLoad ? LOAD : (isStore ? STORE : FETCH_INSTR);
            end
            LOAD: begin
                state <= WAIT_DATA;
            end
            WAIT_DATA: begin
                state <= FETCH_INSTR;
            end
            STORE: begin
                state <= FETCH_INSTR;
            end
        endcase
    end

    wire [31:0] writeBackData;
    wire writeBackEnable;
    always @(posedge clk) begin
        if (writeBackEnable && rdId != 0) begin
`ifdef BENCH	 
            // $display("x%0d <= 0x%0x",rdId,writeBackData);
`endif	 
            RegisterBank[rdId] <= writeBackData;
        end
    end

`ifdef BENCH
    always @(posedge clk ) begin
        if (state == FETCH_INSTR) begin
            case (1'b1)
            // isalureg : $display("alureg rd=x%0d rs1=x%0d rs2=x%0d funct3=%b", rdid, rs1id, rs2id, funct3);
            // isaluimm : $display("aluimm rd=x%0d rs1=x%0d imm=0x%0x funct3=%b", rdid, rs1id, iimm, funct3);
            // isbranch : $display("branch");
            // isjalr   : $display("jalr");
            // isjal    : $display("jal");
            // isauipc  : $display("aluauipc");
            // islui    : $display("lui");
            // isload   : $display("load");
            // isStore  : begin 
            //     $display("store 0x%0x <= 0x%0x", mem_addr, mem_wdata);
            // end
            isSYSTEM : begin 
                $display("END");
                $finish();
            end
            endcase
        end
    end
`endif

    //////////////////////////////////////////////////////////////
    // ALU
    //////////////////////////////////////////////////////////////
    function [31:0] flip32;
        input [31:0] x;
        flip32 = {x[ 0], x[ 1], x[ 2], x[ 3], x[ 4], x[ 5], x[ 6], x[ 7], 
		x[ 8], x[ 9], x[10], x[11], x[12], x[13], x[14], x[15], 
		x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23],
		x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]};
    endfunction
    wire [31:0] aluIn1 = rs1;
    wire [31:0] aluIn2 = isALUreg | isBranch ? rs2 : Iimm;
    reg [31:0] aluOut;
    wire [4:0] shamt = isALUreg ? rs2[4:0] : instr[24:20];

    wire [32:0] aluMinus = {1'b0, aluIn1} - {1'b0, aluIn2}; // X - Y = 1 + X + ~Y
    wire EQ = aluMinus[31:0] == 0;
    wire LTU = aluMinus[32];
    wire LT = (aluIn1[31] ^ aluIn2[31]) ? aluIn1[31] : aluMinus[32];

    wire [31:0] shifter_in = (funct3 == 3'b001) ? flip32(aluIn1) : aluIn1;
    wire [31:0] shifter = $signed({instr[30] & aluIn1[31], shifter_in} >>> aluIn2[4:0]);
    wire [31:0] leftshift = flip32(shifter);

    always @(*) begin
        case (funct3)
        3'b000: aluOut = (funct7[5] & isALUreg) ? aluMinus[31:0] : (aluIn1 + aluIn2);
        3'b001: aluOut = leftshift;
        3'b010: aluOut = {31'b0, LT};
        3'b011: aluOut = {31'b0, LTU};
        3'b100: aluOut = (aluIn1 ^ aluIn2);
        3'b101: aluOut = shifter; 
        3'b110: aluOut = (aluIn1 | aluIn2); 
        3'b111: aluOut = (aluIn1 & aluIn2);
        endcase
    end

    assign writeBackData =  (isJAL || isJALR)   ?   (PC + 4) :
                            isLUI               ?   Uimm :
                            isAUIPC             ?   PC + Uimm :
                            isLoad              ?   load_data :
                                                    aluOut;
    assign writeBackEnable = (state == EXECUTE && (isALUimm || isALUreg || isJAL || isJALR || isLUI || isAUIPC)) || state == WAIT_DATA;

`ifdef BENCH
    // always @(posedge clk) begin
    //     if (state == EXECUTE && (isALUimm || isALUreg)) begin
    //         case (funct3)
    //         3'b000: $display("0x%0x %s 0x%0x = 0x%0x", aluIn1, (funct7[5] & isALUreg) ? "-":"+", aluIn2, aluOut);
    //         3'b001: $display("0x%0x << 0x%0x = 0x%0x", aluIn1, shamt, aluOut);
    //         3'b010: $display("0x%0x < 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
    //         3'b011: $display("0x%0x < 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
    //         3'b100: $display("0x%0x ^ 1x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
    //         3'b101: $display("ALU Shift Right");
    //         3'b110: $display("0x%0x | 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
    //         3'b111: $display("0x%0x & 0x%0x = 0x%0x", aluIn1, aluIn2, aluOut);
    //         endcase
    //     end
    // end
`endif

    //////////////////////////////////////////////////////////////
    // Branch
    //////////////////////////////////////////////////////////////
    reg takeBranch;
    always @(*) begin
        case (funct3) 
        3'b000: takeBranch = EQ;
        3'b001: takeBranch = !EQ;
        3'b100: takeBranch = LT;
        3'b101: takeBranch = !LT; 
        3'b110: takeBranch = LTU; 
        3'b111: takeBranch = !LTU; 
        default: takeBranch = 1'b1;
        endcase
    end

    //////////////////////////////////////////////////////////////
    // Load/Store
    //////////////////////////////////////////////////////////////
    wire [31:0] loadstore_addr = rs1 + (isLoad ? Iimm : Simm);
    wire [15:0] load_halfword = loadstore_addr[1] ? mem_rdata[31:16] : mem_rdata[15:0];
    wire [7:0] load_byte = loadstore_addr[0] ? load_halfword[15:8] : load_halfword[7:0];
    
    wire mem_byte_access = (funct3[1:0] == 2'b00);
    wire mem_halfword_access = (funct3[1:0] == 2'b01);

    wire load_sign = !funct3[2] & (mem_byte_access ? load_byte[7] : load_halfword[15]);
    
    wire [31:0] load_data = 
        mem_byte_access     ?  {{24{load_sign}}, load_byte} :
        mem_halfword_access ?  {{16{load_sign}}, load_byte} :
                               mem_rdata;

    assign mem_wdata[7:0  ] = rs2[7:0];
    assign mem_wdata[15:8 ] = loadstore_addr[0] ? rs2[7:0]  : rs2[15:8];
    assign mem_wdata[23:16] = loadstore_addr[1] ? rs2[7:0]  : rs2[23:16];
    assign mem_wdata[31:24] = loadstore_addr[0] ? rs2[7:0]  : 
                              loadstore_addr[1] ? rs2[15:8] : rs2[31:24];

    wire [3:0] store_wmask =  
            mem_byte_access         ?  (
                loadstore_addr[1]   ? (loadstore_addr[0] ? 4'b1000 : 4'b0100) :
                                      (loadstore_addr[0] ? 4'b0010 : 4'b0001)
            ) :
            mem_halfword_access     ? (loadstore_addr[1] ? 4'b1100 : 4'b0011)  :
                                      4'b1111;

    assign debug = RegisterBank[3];
    assign status = (state == FETCH_INSTR || isSYSTEM);
endmodule