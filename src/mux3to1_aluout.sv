module mux3to1_aluout(
    input [6:0] E_op,
    input [4:0] E_alu_ctrl,
    input [31:0] E_alu_f,
    input [31:0] E_alu,
    input [31:0] E_csr,

    output logic [31:0] E_alu_out
);

always_comb
begin
    if(E_alu_ctrl == 5'd22 || E_alu_ctrl == 5'd23)
        E_alu_out = E_alu_f;
    else if (E_op == 7'b1110011)
        E_alu_out = E_csr;
    else
        E_alu_out = E_alu;
end

endmodule
