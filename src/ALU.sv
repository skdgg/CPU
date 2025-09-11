module ALU(
    input [4:0] alu_control, // Control signal for the ALU
    input [31:0] alu_in1,     // First operand
    input [31:0] alu_in2,     // Second operand

    output logic [31:0] alu_out,   // ALU output
    output logic pc_flag      // PC flag for branch instructions
);

logic [63:0] alu_reg; // Register for multiplication results

always_comb begin
    case(alu_control)
        5'b00000: begin  // ADD, ADDI, LW, SW, AUIPC, LUI, JAL
            alu_reg = 64'd0;
            alu_out = alu_in1 + alu_in2;
            pc_flag = 1'b0;
        end
        5'b00001: begin  // SUB
            alu_reg = 64'd0;
            alu_out = $signed(alu_in1) - $signed(alu_in2);
            pc_flag = 1'b0;
        end
        5'b00010: begin  // SLL, SLLI
            alu_reg = 64'd0;
            alu_out = alu_in1 << alu_in2[4:0];
            pc_flag = 1'b0;
        end
        5'b00011: begin  // SLT, SLTI
            alu_reg = 64'd0;
            alu_out = ($signed(alu_in1) < $signed(alu_in2)) ? 32'b1 : 32'b0;
            pc_flag = 1'b0;
        end
        5'b00100: begin  // SLTU, SLTIU
            alu_reg = 64'd0;
            alu_out = (alu_in1 < alu_in2) ? 32'b1 : 32'b0;
            pc_flag = 1'b0;
        end
        5'b00101: begin  // XOR, XORI
            alu_reg = 64'd0;
            alu_out = alu_in1 ^ alu_in2;
            pc_flag = 1'b0;
        end
        5'b00110: begin  // SRL, SRLI
            alu_reg = 64'd0;
            alu_out = alu_in1 >> alu_in2[4:0];
            pc_flag = 1'b0;
        end
        5'b00111: begin  // SRA, SRAI
            alu_reg = 64'd0;
            alu_out = $signed(alu_in1) >>> alu_in2[4:0];
            pc_flag = 1'b0;
        end
        5'b01000: begin  // OR, ORI
            alu_reg = 64'd0;
            alu_out = alu_in1 | alu_in2;
            pc_flag = 1'b0;
        end
        5'b01001: begin  // AND, ANDI
            alu_reg = 64'd0;
            alu_out = alu_in1 & alu_in2;
            pc_flag = 1'b0;
        end
        5'b01010: begin  // JALR, JAL
            alu_reg = 64'd0;
            alu_out = alu_in1 + 32'd4;
            pc_flag = 1'b0;
        end
        5'b01011: begin  // BEQ
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = (alu_in1 == alu_in2) ? 1'b1 : 1'b0;
        end
        5'b01100: begin  // BNE
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = (alu_in1 != alu_in2) ? 1'b1 : 1'b0;
        end
        5'b01101: begin  // BLT
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = ($signed(alu_in1) < $signed(alu_in2)) ? 1'b1 : 1'b0;
        end
        5'b01110: begin  // BGE
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = ($signed(alu_in1) >= $signed(alu_in2)) ? 1'b1 : 1'b0;
        end
        5'b01111: begin  // BLTU
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = (alu_in1 < alu_in2) ? 1'b1 : 1'b0;
        end
        5'b10000: begin  // BGEU
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = (alu_in1 >= alu_in2) ? 1'b1 : 1'b0;
        end
        5'b10001: begin // MUL
            alu_reg = alu_in1 * alu_in2;
            alu_out = alu_reg[31:0];
            pc_flag = 1'b0;
        end
        5'b10010: begin // MULH
            alu_reg = {{32{alu_in1[31]}},alu_in1} * {{32{alu_in2[31]}},alu_in2};
            alu_out = alu_reg[63:32];
            pc_flag = 1'b0;
        end
        5'b10011: begin // MULHSU
            alu_reg = {{32{alu_in1[31]}},alu_in1} * alu_in2;
            alu_out = alu_reg[63:32];
            pc_flag = 1'b0;
        end
        5'b10100: begin // MULHU
            alu_reg = alu_in1 * alu_in2;
            alu_out = alu_reg[63:32];
            pc_flag = 1'b0;
        end
        5'b10101: begin // LUI
            alu_reg = 64'd0;
            alu_out = alu_in2;
            pc_flag = 1'b0;
        end
        default: begin  // default
            alu_reg = 64'd0;
            alu_out = 32'd0;
            pc_flag = 1'b0;
        end
    endcase
end

endmodule
