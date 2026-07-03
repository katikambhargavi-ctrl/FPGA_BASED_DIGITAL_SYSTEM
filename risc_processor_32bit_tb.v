`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 12:36:59
// Design Name: 
// Module Name: risc_processor_32bit_tb
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
`timescale 1ns/1ps

module risc_processor_32bit_tb;

reg clk;
reg reset;

risc_processor_32bit uut (
    .clk(clk),
    .reset(reset)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Apply reset and initialize registers
initial begin
    reset = 1;
    #10;
    reset = 0;

    // Initialize register file
    uut.RF.registers[1] = 32'd10;   // R1 = 10
    uut.RF.registers[2] = 32'd5;    // R2 = 5

    // Initialize data memory
    uut.DM.memory[3] = 32'd100;

    #100;

    $display("\n===== Register Contents =====");
    $display("R1 = %0d", uut.RF.registers[1]);
    $display("R2 = %0d", uut.RF.registers[2]);
    $display("R3 = %0d (ADD Result)", uut.RF.registers[3]);
    $display("R4 = %0d (SUB Result)", uut.RF.registers[4]);
    $display("R5 = %0d (AND Result)", uut.RF.registers[5]);
    $display("R6 = %0d (OR Result)", uut.RF.registers[6]);
    $display("R7 = %0d (LW Result)", uut.RF.registers[7]);

    $display("\n===== Data Memory =====");
    $display("MEM[3] = %0d", uut.DM.memory[3]);
    $display("MEM[4] = %0d", uut.DM.memory[4]);

    $finish;
end

// Monitor processor operation
initial begin
    $monitor("Time=%0t PC=%0d Instr=%h ALU_Result=%0d",
              $time,
              uut.pc,
              uut.instr,
              uut.alu_result);
end

endmodule