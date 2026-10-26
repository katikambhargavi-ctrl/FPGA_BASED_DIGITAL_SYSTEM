`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.07.2026 10:23:53
// Design Name: 
// Module Name: RISC_V_I
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RISC_V_I(clk,rst);

    input clk,rst;

    wire [31:0] PC_Top,RD_Instr,RD1_Top,Imm_Ext_Top,ALUResult,ReadData;
    wire [31:0] PCPlus4,RD2_Top,SrcB,Result,PCTarget,PC_Next_Top;
    wire RegWrite,MemWrite,ALUSrc,ResultSrc,PCSrc,Zero_Top;
    wire [1:0]ImmSrc;
    wire [2:0]ALUControl_Top;

    // ---------------- PC logic ----------------
    PC_Module PC(
        .clk(clk),
        .rst(rst),
        .PC(PC_Top),
        .PC_Next(PC_Next_Top)
    );

    PC_Adder PC_Adder_Plus4(
                    .a(PC_Top),
                    .b(32'd4),
                    .c(PCPlus4)
    );

    // FIX #3a: added missing branch-target adder (PC + ImmExt)
    PC_Adder PC_Adder_Target(
                    .a(PC_Top),
                    .b(Imm_Ext_Top),
                    .c(PCTarget)
    );

    // FIX #3b: added missing PCNext mux, selected by PCSrc
    Mux Mux_PCSrc(
                    .a(PCPlus4),
                    .b(PCTarget),
                    .s(PCSrc),
                    .c(PC_Next_Top)
    );

    // ---------------- Fetch ----------------
    Instruction_Memory Instruction_Memory(
                            .rst(rst),
                            .A(PC_Top),
                            .RD(RD_Instr)
    );

    // ---------------- Decode / Register File ----------------
    Register_File Register_File(
                            .clk(clk),
                            .rst(rst),
                            .WE3(RegWrite),
                            .WD3(Result),
                            .A1(RD_Instr[19:15]),
                            .A2(RD_Instr[24:20]),
                            .A3(RD_Instr[11:7]),
                            .RD1(RD1_Top),
                            .RD2(RD2_Top)
    );

    // FIX #5: ImmSrc connected as full [1:0] bus (was ImmSrc[0] only)
    Sign_Extend Sign_Extend(
                        .In(RD_Instr),
                        .ImmSrc(ImmSrc),
                        .Imm_Ext(Imm_Ext_Top)
    );

    // ---------------- Execute ----------------
    Mux Mux_Register_to_ALU(
                            .a(RD2_Top),
                            .b(Imm_Ext_Top),
                            .s(ALUSrc),
                            .c(SrcB)
    );

    ALU ALU(
            .A(RD1_Top),
            .B(SrcB),
            .Result(ALUResult),
            .ALUControl(ALUControl_Top),
            .OverFlow(),
            .Carry(),
            .Zero(Zero_Top),
            .Negative()
    );

    // FIX #2 + #4: Zero now feeds the control unit, PCSrc comes out
    // of it, and funct7 is wired from the correct instruction bits
    // (was mistakenly wired to the opcode field).
    Control_Unit_Top Control_Unit_Top(
                            .Op(RD_Instr[6:0]),
                            .Zero(Zero_Top),
                            .RegWrite(RegWrite),
                            .ImmSrc(ImmSrc),
                            .ALUSrc(ALUSrc),
                            .MemWrite(MemWrite),
                            .ResultSrc(ResultSrc),
                            .PCSrc(PCSrc),
                            .funct3(RD_Instr[14:12]),
                            .funct7(RD_Instr[31:25]),
                            .ALUControl(ALUControl_Top)
    );

    // ---------------- Memory ----------------
    Data_Memory Data_Memory(
                        .clk(clk),
                        .rst(rst),
                        .WE(MemWrite),
                        .WD(RD2_Top),
                        .A(ALUResult),
                        .RD(ReadData)
    );

    // ---------------- Writeback ----------------
    Mux Mux_DataMemory_to_Register(
                            .a(ALUResult),
                            .b(ReadData),
                            .s(ResultSrc),
                            .c(Result)
    );

endmodule

module ALU(A,B,Result,ALUControl,OverFlow,Carry,Zero,Negative);

    input [31:0]A,B;
    input [2:0]ALUControl;
    output Carry,OverFlow,Zero,Negative;
    output [31:0]Result;

    wire Cout;
    wire [31:0]Sum;

    assign {Cout,Sum} = (ALUControl[0] == 1'b0) ? A + B :
                                          (A + ((~B)+1)) ;
    assign Result = (ALUControl == 3'b000) ? Sum :
                    (ALUControl == 3'b001) ? Sum :
                    (ALUControl == 3'b010) ? A & B :
                    (ALUControl == 3'b011) ? A | B :
                    (ALUControl == 3'b101) ? {{31{1'b0}},(Sum[31])} : {32{1'b0}};

    assign OverFlow = ((Sum[31] ^ A[31]) &
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule


module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);

    input [1:0]ALUOp;
    input [2:0]funct3;
    input [6:0]funct7,op;
    output [2:0]ALUControl;

    assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :
                        (ALUOp == 2'b01) ? 3'b001 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} == 2'b11)) ? 3'b001 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} != 2'b11)) ? 3'b000 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b010)) ? 3'b101 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b110)) ? 3'b011 :
                        ((ALUOp == 2'b10) & (funct3 == 3'b111)) ? 3'b010 :
                                                                  3'b000 ;
endmodule


module Main_Decoder(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp);
    input [6:0]Op;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc,ALUOp;

    // FIX #6: RegWrite was missing I-type ALU-immediate instructions
    // (addi, andi, ori, slti, ...  opcode 0010011), so they could
    // never write their result back to the register file.
    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 | Op == 7'b0010011) ? 1'b1 :
                                                              1'b0 ;
    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 :
                    (Op == 7'b1100011) ? 2'b10 :
                                         2'b00 ;
    // FIX #7: ALUSrc had the same omission -- without it, addi would
    // route RD2 (a register) into the ALU instead of the immediate.
    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 :
                                                            1'b0 ;
    assign MemWrite = (Op == 7'b0100011) ? 1'b1 :
                                           1'b0 ;
    assign ResultSrc = (Op == 7'b0000011) ? 1'b1 :
                                            1'b0 ;
    assign Branch = (Op == 7'b1100011) ? 1'b1 :
                                         1'b0 ;
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :
                   (Op == 7'b1100011) ? 2'b01 :
                                        2'b00 ;

endmodule


// -----------------------------------------------------------------
// FIX #2: Control_Unit_Top now accepts Zero and outputs PCSrc
// (Branch AND Zero), matching the diagram, instead of a dangling
// Branch output that nothing ever used.
// -----------------------------------------------------------------
module Control_Unit_Top(Op,Zero,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,PCSrc,funct3,funct7,ALUControl);

    input [6:0]Op,funct7;
    input [2:0]funct3;
    input Zero;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,PCSrc;
    output [1:0]ImmSrc;
    output [2:0]ALUControl;

    wire [1:0]ALUOp;
    wire Branch;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp)
    );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );

    assign PCSrc = Branch & Zero;

endmodule


module Data_Memory(clk,rst,WE,WD,A,RD);

    input clk,rst,WE;
    input [31:0]A,WD;
    output [31:0]RD;

    reg [31:0] mem [1023:0];

    always @ (posedge clk)
    begin
        if(WE)
            mem[A[31:2]] <= WD;
    end

    // FIX #8 (same reasoning as Instruction_Memory / Register_File):
    // don't mask a combinational read on rst.
    assign RD = mem[A[31:2]];

    initial begin
        mem[28] = 32'h00000020;
    end

endmodule


module Instruction_Memory(rst,A,RD);

  input rst;
  input [31:0]A;
  output [31:0]RD;

  reg [31:0] mem [1023:0];

  // FIX #8: reads are no longer gated by rst. Reset should only hold
  // the PC at 0 (via PC_Module); it has no business zeroing out a
  // combinational memory read. With the old gating, PC=0 and rst=0
  // were true at the same time by construction, so the instruction
  // at address 0 could never actually be observed -- it was always
  // masked to zero, and by the time rst released, PC had already
  // advanced to 4.
  assign RD = mem[A[31:2]];

endmodule


module Mux (a,b,s,c);

    input [31:0]a,b;
    input s;
    output [31:0]c;

    assign c = (~s) ? a : b ;

endmodule


module PC_Module(clk,rst,PC,PC_Next);
    input clk,rst;
    input [31:0]PC_Next;
    output [31:0]PC;
    reg [31:0]PC;

    always @(posedge clk or negedge rst)
    begin
        if(~rst)
            PC <= {32{1'b0}};
        else
            PC <= PC_Next;
    end
endmodule


module PC_Adder (a,b,c);

    input [31:0]a,b;
    output [31:0]c;

    assign c = a + b;

endmodule


module Register_File(clk,rst,WE3,WD3,A1,A2,A3,RD1,RD2);

    input clk,rst,WE3;
    input [4:0]A1,A2,A3;
    input [31:0]WD3;
    output [31:0]RD1,RD2;

    reg [31:0] Register [31:0];

    always @ (posedge clk)
    begin
       if(WE3 && A3 != 0)
            Register[A3] <= WD3;
    end

    // FIX #8 (same reasoning as Instruction_Memory): reset should not
    // mask register reads. Register writes were never gated by rst in
    // the always block above, so leaving the reads gated only meant
    // the first instruction (which needs x5/x6 while PC is still 0,
    // i.e. still "in reset") would read 0 instead of their real values.
    assign RD1 = Register[A1];
    assign RD2 = Register[A2];

    // FIX #9: x0 must read as a hardwired 0. Writes to it were already
    // blocked above (A3 != 0), but nothing ever initialized it, so an
    // uninitialized reg array element defaults to X in simulation --
    // every instruction that reads x0 (sw/lw base register, etc.) was
    // silently inheriting X. Since writes stay blocked, this initial
    // value holds for the whole simulation.
    initial begin
        Register[0] = 32'h00000000;
        Register[5] = 32'h00000005;
        Register[6] = 32'h00000004;
    end

endmodule


// -----------------------------------------------------------------
// FIX #1: ImmSrc widened to [1:0] so the B-type (branch) case
// (ImmSrc==2'b10) is actually reachable. Previously this port was
// declared as a single bit, so 2'b10 could never match.
// -----------------------------------------------------------------
module Sign_Extend (In,Imm_Ext,ImmSrc);

    input [31:0]In;
    input [1:0]ImmSrc;
    output [31:0]Imm_Ext;

    assign Imm_Ext =
       (ImmSrc==2'b00) ?
           {{20{In[31]}},In[31:20]} :

       (ImmSrc==2'b01) ?
           {{20{In[31]}},In[31:25],In[11:7]} :

       (ImmSrc==2'b10) ?
           {{19{In[31]}},
             In[31],
             In[7],
             In[30:25],
             In[11:8],
             1'b0} :

       32'b0;

endmodule
