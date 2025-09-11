module mux2to1_PC(
    input [31:0] in_1,
    input [31:0] in_2,
    input [31:0] F_PC,
    input stall,
    input d_rst,
    input next_pc_sel,

    output logic [31:0] out
);

always_comb
    begin
        if(~d_rst)            out = 32'd0;
        else if(stall)       out = F_PC;
        else if(next_pc_sel) out = in_2;
        else                 out = in_1;
    end


endmodule
