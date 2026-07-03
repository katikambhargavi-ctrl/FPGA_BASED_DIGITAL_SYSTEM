`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 12:35:56
// Design Name: 
// Module Name: risc_processor_32bit
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


module risc_processor_32bit(
    input clk,
    input reset
);

wire [31:0] pc, next_pc, instr;
wire [31:0] read_data1, read_data2;
wire [31:0] alu_result, mem_data;
wire [31:0] sign_ext_imm, alu_input2;
wire [31:0] pc_plus4, branch_addr;
wire [4:0] write_reg;
wire [3:0] alu_control;
wire zero;

wire reg_dst, alu_src, mem_to_reg;
wire reg_write, mem_read, mem_write;
wire branch;
wire [1:0] alu_op;

assign pc_plus4 = pc + 32'd4;
assign branch_addr = pc_plus4 + (sign_ext_imm << 2);
assign next_pc = (branch & zero) ? branch_addr : pc_plus4;

pc_reg PC(clk, reset, next_pc, pc);

instruction_memory IM(pc, instr);

control_unit CU(
    instr[31:26],
    reg_dst,
    alu_src,
    mem_to_reg,
    reg_write,
    mem_read,
    mem_write,
    branch,
    alu_op
);

register_file RF(
    clk,
    reg_write,
    instr[25:21],
    instr[20:16],
    write_reg,
    mem_to_reg ? mem_data : alu_result,
    read_data1,
    read_data2
);

assign write_reg = reg_dst ? instr[15:11] : instr[20:16];

sign_extend SE(instr[15:0], sign_ext_imm);

assign alu_input2 = alu_src ? sign_ext_imm : read_data2;

alu_control_unit ACU(alu_op, instr[5:0], alu_control);

alu ALU(read_data1, alu_input2, alu_control, alu_result, zero);

data_memory DM(
    clk,
    mem_read,
    mem_write,
    alu_result,
    read_data2,
    mem_data
);

endmodule


module pc_reg(
    input clk,
    input reset,
    input [31:0] next_pc,
    output reg [31:0] pc
);

always @(posedge clk or posedge reset) begin
    if(reset)
        pc <= 32'd0;
    else
        pc <= next_pc;
end

endmodule


module instruction_memory(
    input [31:0] addr,
    output [31:0] instr
);

reg [31:0] memory [0:255];

initial begin
    memory[0] = 32'b000000_00001_00010_00011_00000_100000; // ADD R3,R1,R2
    memory[1] = 32'b000000_00001_00010_00100_00000_100010; // SUB R4,R1,R2
    memory[2] = 32'b000000_00001_00010_00101_00000_100100; // AND R5,R1,R2
    memory[3] = 32'b000000_00001_00010_00110_00000_100101; // OR  R6,R1,R2
    memory[4] = 32'b100011_00001_00111_0000000000000100;   // LW  R7,4(R1)
    memory[5] = 32'b101011_00001_00111_0000000000001000;   // SW  R7,8(R1)
    memory[6] = 32'b000100_00001_00010_0000000000000010;   // BEQ R1,R2,offset
end

assign instr = memory[addr[9:2]];

endmodule


module control_unit(
    input [5:0] opcode,
    output reg reg_dst,
    output reg alu_src,
    output reg mem_to_reg,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg [1:0] alu_op
);

always @(*) begin
    case(opcode)

        6'b000000: begin // R-type
            reg_dst = 1'b1;
            alu_src = 1'b0;
            mem_to_reg = 1'b0;
            reg_write = 1'b1;
            mem_read = 1'b0;
            mem_write = 1'b0;
            branch = 1'b0;
            alu_op = 2'b10;
        end

        6'b100011: begin // LW
            reg_dst = 1'b0;
            alu_src = 1'b1;
            mem_to_reg = 1'b1;
            reg_write = 1'b1;
            mem_read = 1'b1;
            mem_write = 1'b0;
            branch = 1'b0;
            alu_op = 2'b00;
        end

        6'b101011: begin // SW
            reg_dst = 1'b0;
            alu_src = 1'b1;
            mem_to_reg = 1'b0;
            reg_write = 1'b0;
            mem_read = 1'b0;
            mem_write = 1'b1;
            branch = 1'b0;
            alu_op = 2'b00;
        end

        6'b000100: begin // BEQ
            reg_dst = 1'b0;
            alu_src = 1'b0;
            mem_to_reg = 1'b0;
            reg_write = 1'b0;
            mem_read = 1'b0;
            mem_write = 1'b0;
            branch = 1'b1;
            alu_op = 2'b01;
        end

        default: begin
            reg_dst = 1'b0;
            alu_src = 1'b0;
            mem_to_reg = 1'b0;
            reg_write = 1'b0;
            mem_read = 1'b0;
            mem_write = 1'b0;
            branch = 1'b0;
            alu_op = 2'b00;
        end

    endcase
end

endmodule


module register_file(
    input clk,
    input reg_write,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);

reg [31:0] registers [0:31];

integer i;

initial begin
    for(i = 0; i < 32; i = i + 1)
        registers[i] = 32'd0;

    registers[1] = 32'd10;
    registers[2] = 32'd5;
end

assign read_data1 = registers[read_reg1];
assign read_data2 = registers[read_reg2];

always @(posedge clk) begin
    if(reg_write && write_reg != 5'd0)
        registers[write_reg] <= write_data;
end

endmodule


module sign_extend(
    input [15:0] imm16,
    output [31:0] imm32
);

assign imm32 = {{16{imm16[15]}}, imm16};

endmodule


module alu_control_unit(
    input [1:0] alu_op,
    input [5:0] funct,
    output reg [3:0] alu_control
);

always @(*) begin
    case(alu_op)

        2'b00: alu_control = 4'b0010; // ADD for LW/SW

        2'b01: alu_control = 4'b0110; // SUB for BEQ

        2'b10: begin
            case(funct)
                6'b100000: alu_control = 4'b0010; // ADD
                6'b100010: alu_control = 4'b0110; // SUB
                6'b100100: alu_control = 4'b0000; // AND
                6'b100101: alu_control = 4'b0001; // OR
                6'b101010: alu_control = 4'b0111; // SLT
                default:   alu_control = 4'b0010;
            endcase
        end

        default: alu_control = 4'b0010;

    endcase
end

endmodule


module alu(
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_control,
    output reg [31:0] result,
    output zero
);

always @(*) begin
    case(alu_control)
        4'b0000: result = a & b;
        4'b0001: result = a | b;
        4'b0010: result = a + b;
        4'b0110: result = a - b;
        4'b0111: result = (a < b) ? 32'd1 : 32'd0;
        default: result = 32'd0;
    endcase
end

assign zero = (result == 32'd0);

endmodule


module data_memory(
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] write_data,
    output [31:0] read_data
);

reg [31:0] memory [0:255];

integer i;

initial begin
    for(i = 0; i < 256; i = i + 1)
        memory[i] = 32'd0;

    memory[3] = 32'd100;
end

assign read_data = mem_read ? memory[addr[9:2]] : 32'd0;

always @(posedge clk) begin
    if(mem_write)
        memory[addr[9:2]] <= write_data;
end

endmodule
