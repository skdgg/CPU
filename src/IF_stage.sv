`include "../src/PC.sv"
`include "../src/PC_adder.sv"
`include "../src/mux2to1_PC.sv"

module IF_stage (
    input               clk,
    input               rst,
    input               stall,
    input               next_pc_sel,
    input        [31:0] jb_pc,

    output       [31:0] next_pc,
    output       [31:0] F_PC
);

    logic [31:0] pc_plus_4_out;

    PC pc_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_in(next_pc),
        .pc_out(F_PC)
    );

    // PC+4
    PC_adder pc_adder (
        .in_a(F_PC),
        .in_b(32'd4),
        .sum_out(pc_plus_4_out)
    );

    mux2to1_PC mux2to1_PC(
        .in_1(pc_plus_4_out),
        .in_2(jb_pc),
        .F_PC(F_PC),
        .stall(stall),
        .d_rst(d_rst),
        .next_pc_sel(next_pc_sel),
        
        .out(next_pc)
    );

endmodule
