/*
 *  CPU Top Level
 *  This module connects all the pipeline stages together.
 */

`include "../src/IF_stage.sv"
`include "../src/FD_reg.sv"
`include "../src/ID_stage.sv"
`include "../src/DE_reg.sv"
`include "../src/Exe_stage.sv"
`include "../src/EM_reg.sv"
`include "../src/MW_reg.sv"
`include "../src/WB_stage.sv"

module CPU (
    input  logic        clk,
    input  logic        rst,

    // ------------------------------
    // Instruction Memory (read-only)
    // ------------------------------
    input  logic [31:0] im_data_in,  
    output logic [13:0] im_addr,     

    // ------------------------------
    // Data Memory (read/write)
    // ------------------------------
    input  logic [31:0] dm_data_out, 
    output logic [13:0] dm_addr,     
    output logic [31:0] dm_data_in,  
    output logic        dm_web,      
    output logic [31:0] dm_bweb      
);

    logic stall;
    logic flush;

    // IF Stage signals
    logic pc_sel;
    logic [31:0] jb_pc;
    logic [31:0] next_pc;
    logic [31:0] F_PC;

    // ID Stage signals
    logic [31:0] D_PC;
    logic [31:0] D_instruction;
    logic [6:0]  D_opcode;
    logic [2:0]  D_funct3;
    logic [4:0]  D_rd;
    logic [4:0]  D_rs1;
    logic [4:0]  D_rs2;
    logic [4:0]  D_rd_f;
    logic [4:0]  D_rs1_f;
    logic [4:0]  D_rs2_f;
    logic [31:0] D_rs1_data;
    logic [31:0] D_rs2_data;
    logic [31:0] D_rs1_data_f;
    logic [31:0] D_rs2_data_f;
    logic [31:0] D_imm;
    logic [4:0]  D_alu_control;
    logic        D_reg_write_enable;
    logic        D_reg_write_enable_f;
    logic        D_JAL;
    logic        D_JALR;
    logic        D_alu_op1_sel;
    logic        D_alu_op2_sel;
    logic        D_wb_data_sel;
    logic [31:0] D_dm_write_enable;
    logic        D_web;
    logic D_jb_op1_sel;
    // EX Stage signals
    logic        next_pc_sel;     
    logic [31:0] E_imm;  
    logic [6:0]  E_op;
    logic [31:0] E_alu_out, E_alu_out_f, E_DM_data, E_csr_out;
    logic E_alu_op1_sel;
    logic E_alu_op2_sel;
    logic E_wb_data_sel;
    logic [31:0] E_dm_write_enable;  
    logic E_web;
    // MW Register signals
    logic [6:0]  M_op;
    logic [4:0]  M_rd, M_rd_f;
    logic [2:0]  M_funct3;
    logic        M_reg_write_enable, M_reg_write_enable_f;
    logic        M_wb_data_select;
    logic [31:0] M_dm_write_enable;
    logic        M_web;
    logic [31:0] M_ALU_out, M_DM_data;
    logic [31:0] M_rd_data; 

    // WB Stage signals
    logic        W_reg_write_enable;
    logic        W_reg_write_enable_f;
    logic [31:0] W_rd_data;
    logic [31:0] W_alu_out;
    logic [4:0]  W_rd, W_rd_f;
    logic [2:0]  W_funct3;
    logic        W_wb_data_select;
    logic [31:0] LD_data;

    //  Word-addressed SRAM
    always_comb begin
        im_addr = next_pc   [15:2];   
        dm_addr = M_ALU_out [15:2];   
    end


    // Store data aligner + byte write mask (active-low BWEB)
    always_comb begin
        if (M_op == 7'b0100011) begin  // S-type (store)
            unique case (M_funct3)
            // -------- SW (store word, 32-bit) --------
            3'b010: begin
                dm_data_in = M_DM_data;
                dm_bweb    = M_dm_write_enable;
            end

            // -------- SB (store byte, 8-bit) --------
            3'b000: begin
                unique case (M_ALU_out[1:0])
                2'b11: begin
                    dm_data_in = { M_DM_data[7:0], 24'd0 };
                    dm_bweb    = { M_dm_write_enable[7:0], 24'hFF_FFFF };
                end
                2'b10: begin
                    dm_data_in = { M_DM_data[15:0], 16'd0 };
                    dm_bweb    = { M_dm_write_enable[15:0], 16'hFFFF };
                end
                2'b01: begin
                    dm_data_in = { M_DM_data[23:0], 8'd0 };
                    dm_bweb    = { M_dm_write_enable[23:0], 8'hFF };
                end
                default: begin
                    dm_data_in = M_DM_data;
                    dm_bweb    = M_dm_write_enable;
                end
                endcase
            end

            // -------- SH (store halfword, 16-bit) --------
            3'b001: begin
                unique case (M_ALU_out[1:0])
                2'b10: begin
                    dm_data_in = { M_DM_data[15:0], 16'd0 };
                    dm_bweb    = { M_dm_write_enable[15:0], 16'hFFFF };
                end
                default: begin
                    dm_data_in = M_DM_data;
                    dm_bweb    = M_dm_write_enable;
                end
                endcase
            end

            default: begin
                dm_data_in = 32'd0;
                dm_bweb    = 32'hFFFF_FFFF; 
            end
            endcase
        end else begin
            dm_data_in = M_DM_data;
            dm_bweb    = M_dm_write_enable;
        end
    end

    // Instantiate the pipeline stages
    IF_stage if_stage (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .next_pc_sel(next_pc_sel),
        .jb_pc(jb_pc),
        .next_pc(next_pc),
        .F_PC(F_PC)
    );

    FD_reg fd_reg (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .F_PC(F_PC),
        .F_instruction(im_data_in),
        .D_PC(D_PC),
        .D_instruction(D_instruction)
    );

    ID_stage id_stage (
        .clk                 (clk),
        .rst                 (rst),

        // From IF stage
        .D_PC                (D_PC),
        .D_instruction       (D_instruction),

        // From WB stage
        .W_write_enable      (W_reg_write_enable),
        .W_write_enable_f    (W_reg_write_enable_f),
        .W_rd                (W_rd),
        .W_rd_data           (W_rd_data),

        // Decoded fields / control to next stage
        .D_opcode            (D_opcode),
        .D_funct3            (D_funct3),
        .D_rd                (D_rd),
        .D_rs1               (D_rs1),
        .D_rs2               (D_rs2),
        .D_rd_f              (D_rd_f),
        .D_rs1_f             (D_rs1_f),
        .D_rs2_f             (D_rs2_f),

        // Register file read data
        .D_rs1_data          (D_rs1_data),
        .D_rs2_data          (D_rs2_data),
        .D_rs1_data_f        (D_rs1_data_f),
        .D_rs2_data_f        (D_rs2_data_f),

        // Immediate & ALU control
        .D_imm               (D_imm),
        .D_alu_control       (D_alu_control),

        // Write-back / control signals
        .D_reg_write_enable  (D_reg_write_enable),
        .D_reg_write_enable_f(D_reg_write_enable_f),
        .D_JAL               (D_JAL),
        .D_JALR              (D_JALR),
        .D_alu_op1_sel       (D_alu_op1_sel),
        .D_alu_op2_sel       (D_alu_op2_sel),
        .D_wb_data_sel       (D_wb_data_sel),
        .D_jb_op1_sel       (D_jb_op1_sel),
        // Data memory write enables (active-low byte mask & WEB)
        .D_dm_write_enable   (D_dm_write_enable),
        .D_web               (D_web)
    );

    DE_reg de_reg (
        .clk                  (clk),
        .rst                  (rst),
        .stall                (stall),
        .flush                (flush),

        // Inputs from ID stage
        .D_pc                 (D_pc),
        .D_op                 (D_op),
        .D_funct3             (D_funct3),
        .D_rd                 (D_rd),
        .D_rs1                (D_rs1),
        .D_rs2                (D_rs2),
        .D_rd_f               (D_rd_f),
        .D_rs1_f              (D_rs1_f),
        .D_rs2_f              (D_rs2_f),
        .D_rs1_data           (D_rs1_data),
        .D_rs2_data           (D_rs2_data),
        .D_rs1_data_f         (D_rs1_data_f),
        .D_rs2_data_f         (D_rs2_data_f),
        .D_imm                (D_imm),
        .D_alu_control        (D_alu_control),
        .D_reg_write_enable   (D_reg_write_enable),
        .D_reg_write_enable_f (D_reg_write_enable_f),
        .D_JAL                (D_JAL),
        .D_JALR               (D_JALR),
        .D_jb_op1_sel         (D_jb_op1_sel),
        .D_alu_op1_sel        (D_alu_op1_sel),
        .D_alu_op2_sel        (D_alu_op2_sel),
        .D_wb_data_sel        (D_wb_data_sel),
        .D_dm_write_enable    (D_dm_write_enable),
        .D_web                (D_web),

        // Outputs to EX stage
        .E_pc                 (E_pc),
        .E_op                 (E_op),
        .E_funct3             (E_funct3),
        .E_rd                 (E_rd),
        .E_rs1                (E_rs1),
        .E_rs2                (E_rs2),
        .E_rd_f               (E_rd_f),
        .E_rs1_f              (E_rs1_f),
        .E_rs2_f              (E_rs2_f),
        .E_rs1_data           (E_rs1_data),
        .E_rs2_data           (E_rs2_data),
        .E_rs1_data_f         (E_rs1_data_f),
        .E_rs2_data_f         (E_rs2_data_f),
        .E_imm                (E_imm),
        .E_alu_control        (E_alu_control),
        .E_reg_write_enable   (E_reg_write_enable),
        .E_reg_write_enable_f (E_reg_write_enable_f),
        .E_JAL                (E_JAL),
        .E_JALR               (E_JALR),
        .E_jb_op1_sel         (E_jb_op1_sel),
        .E_alu_op1_sel        (E_alu_op1_sel),
        .E_alu_op2_sel        (E_alu_op2_sel),
        .E_wb_data_sel        (E_wb_data_sel),
        .E_dm_write_enable    (E_dm_write_enable),
        .E_web                (E_web)
    );


    // ======================
    // EXE stage instance
    // ======================
    Exe_stage exe_stage (
        .clk                    (clk),
        .rst                    (rst),
        .E_pc                   (E_pc),
        .E_imm                  (E_imm),
        .E_rs1                  (E_rs1),
        .E_rs2                  (E_rs2),
        .E_rs1_f                (E_rs1_f),
        .E_rs2_f                (E_rs2_f),
        .M_rd                   (M_rd),
        .W_rd                   (W_rd),
        .M_rd_f                 (M_rd_f),
        .W_rd_f                 (W_rd_f),
        .M_reg_write_enable     (M_reg_write_enable),
        .M_reg_write_enable_f   (M_reg_write_enable_f),
        .W_reg_write_enable     (W_reg_write_enable),
        .W_reg_write_enable_f   (W_reg_write_enable_f),

        // Forwarded data
        .E_rs1_data             (E_rs1_data),
        .E_rs2_data             (E_rs2_data),
        .E_rs1_data_f           (E_rs1_data_f),
        .E_rs2_data_f           (E_rs2_data_f),
        .M_rd_data              (M_rd_data),
        .W_rd_data              (W_rd_data),

        .E_JAL                  (E_JAL),
        .E_JALR                 (E_JALR),
        .E_alu_op1_sel          (E_alu_op1_sel),
        .E_alu_op2_sel          (E_alu_op2_sel),
        .E_jb_op1_sel           (E_jb_op1_sel),

        .E_alu_ctrl             (E_alu_ctrl),
        .E_op                   (E_op),
        .E_rd                   (E_rd),
        .E_rd_f                 (E_rd_f),
        .D_rs1                  (D_rs1),
        .D_rs2                  (D_rs2),
        .D_rs1_f                (D_rs1_f),
        .D_rs2_f                (D_rs2_f),

        .flush                  (flush),
        .stall                  (stall),
        .next_pc_sel            (next_pc_sel),
        .E_alu_out              (E_alu_out),
        .E_alu_out_f            (E_alu_out_f),
        .E_DM_data              (E_DM_data),
        .E_csr_out              (E_csr_out),
        .jb_pc                  (jb_pc)
    );

    EM_reg em_reg (
        .clk                    (clk),
        .rst                    (rst),

        // Control/ID from EX
        .E_op                   (E_op),
        .E_rd                   (E_rd),
        .E_rd_f                 (E_rd_f),
        .E_alu_ctrl             (E_alu_ctrl),
        .E_funct3               (E_funct3),
        .E_reg_write_enable     (E_reg_write_enable),
        .E_reg_write_enable_f   (E_reg_write_enable_f),
        .E_wb_data_select       (E_wb_data_select),
        .E_dm_write_enable      (E_dm_write_enable),
        .E_web                  (E_web),

        // Data from EX
        .E_alu_out              (E_alu_out),
        .E_alu_out_f            (E_alu_out_f),
        .E_dm_data              (E_dm_data),
        .E_csr_out              (E_csr_out),

        // To MEM
        .M_op                   (M_op),
        .M_rd                   (M_rd),
        .M_rd_f                 (M_rd_f),
        .M_funct3               (M_funct3),
        .M_reg_write_enable     (M_reg_write_enable),
        .M_reg_write_enable_f   (M_reg_write_enable_f),
        .M_wb_data_select       (M_wb_data_select),
        .M_dm_write_enable      (M_dm_write_enable),
        .M_web                  (M_web),

        // Data to MEM
        .M_alu_out              (M_alu_out),
        .M_dm_data              (M_dm_data)
    );


    MW_reg u_mw_reg (
        .clk                   (clk),
        .rst                   (rst),

        // From MEM stage
        .M_alu_out             (M_alu_out),
        .M_rd                  (M_rd),
        .M_rd_f                (M_rd_f),
        .M_funct3              (M_funct3),
        .M_reg_write_enable    (M_reg_write_enable),
        .M_reg_write_enable_f  (M_reg_write_enable_f),
        .M_wb_data_select      (M_wb_data_select),

        // To WB stage
        .W_alu_out             (W_alu_out),
        .W_rd                  (W_rd),
        .W_rd_f                (W_rd_f),
        .W_funct3              (W_funct3),
        .W_reg_write_enable    (W_reg_write_enable),
        .W_reg_write_enable_f  (W_reg_write_enable_f),
        .W_wb_data_select      (W_wb_data_select)
    );
    WB_stage u_wb_stage (
        .W_wb_data_select      (W_wb_data_select),
        .W_funct3              (W_funct3),
        .LD_data               (dm_data_out),     
        .W_alu_out             (W_alu_out),

        // To register file
        .W_rd_data             (W_rd_data)
    );

endmodule
