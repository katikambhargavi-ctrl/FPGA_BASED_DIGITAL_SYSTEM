`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.07.2026 11:07:33
// Design Name: 
// Module Name: RISC_V_I_tb
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

module RISC_V_I_tb;

    reg clk;
    reg rst;

    // Instantiate the DUT
    RISC_V_I dut (
        .clk(clk),
        .rst(rst)
    );

    // ---------------- Clock generation ----------------
    // 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------- Load test program ----------------
    // Loaded via hierarchical reference into the DUT's instruction
    // memory array. Do this before releasing reset.
    initial begin
        dut.Instruction_Memory.mem[0] = 32'h006283b3; // add  x7,  x5, x6
        dut.Instruction_Memory.mem[1] = 32'h00a38e13; // addi x28, x7, 10
        dut.Instruction_Memory.mem[2] = 32'h01c02023; // sw   x28, 0(x0)
        dut.Instruction_Memory.mem[3] = 32'h00000e83; // lw   x29, 0(x0)
        dut.Instruction_Memory.mem[4] = 32'h01de0463; // beq  x28, x29, 8
        dut.Instruction_Memory.mem[5] = 32'h06300f13; // addi x30, x0, 99  (skipped)
        dut.Instruction_Memory.mem[6] = 32'h03700f93; // addi x31, x0, 55  (branch target)
    end

    // ---------------- Reset sequence ----------------
    // rst is active-LOW in this design (PC_Module clears on ~rst).
    initial begin
        rst = 1'b0;           // hold in reset
        repeat (2) @(posedge clk);
        rst = 1'b1;            // release reset, normal operation begins
    end

    // ---------------- Cycle-by-cycle trace (Tcl Console) ----------------
    initial begin
        $display("time\tPC\t\tInstr\t\tPCSrc\tRegWrite\tResult");
        forever begin
            @(posedge clk);
            #1; // let signals settle after the clock edge
            $display("%0t\t%h\t%h\t%b\t%b\t\t%h",
                $time, dut.PC_Top, dut.RD_Instr, dut.PCSrc,
                dut.RegWrite, dut.Result);
        end
    end

    // ---------------- Run and self-check ----------------
    initial begin
        // hold reset (2 cycles) + 7 instructions, extra margin for
        // single-cycle timing -> 15 cycles is comfortably enough
        repeat (15) @(posedge clk);
        #1;

        $display("\n===== Final Register Values =====");
        $display("x7  (expect 9)  = %0d", dut.Register_File.Register[7]);
        $display("x28 (expect 19) = %0d", dut.Register_File.Register[28]);
        $display("x29 (expect 19) = %0d", dut.Register_File.Register[29]);
        $display("x30 (must NOT become 99 -- proves the branch skip worked) = %0d", dut.Register_File.Register[30]);
        $display("x31 (expect 55, branch target)     = %0d", dut.Register_File.Register[31]);
        $display("mem[0] (expect 19) = %0d", dut.Data_Memory.mem[0]);

        // Basic self-check
        if (dut.Register_File.Register[7]  == 32'd9  &&
            dut.Register_File.Register[28] == 32'd19 &&
            dut.Register_File.Register[29] == 32'd19 &&
            dut.Register_File.Register[30] !== 32'd99 &&
            dut.Register_File.Register[31] == 32'd55 &&
            dut.Data_Memory.mem[0]         == 32'd19)
            $display("\nTEST PASSED: R-type, I-type, load/store, and branch-taken all correct.");
        else
            $display("\nTEST FAILED: check trace above against expected values.");

        $finish;
    end

endmodule
