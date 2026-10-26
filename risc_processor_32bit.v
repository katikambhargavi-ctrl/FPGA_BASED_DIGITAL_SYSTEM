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
