module FD_reg (
    input               clk,
    input               rst,
    input               stall,
    input               flush,

    // Data from IF stage
    input        [31:0] F_PC,
    input        [31:0] F_instruction,

    // Data to ID stage
    output logic [31:0] D_PC,
    output logic [31:0] D_instruction
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, clear the register's contents
            D_PC <= 32'd0;
            D_instruction <= 32'd0;
        end else if (flush) begin
            // On flush, clear the register to nullify the instruction
            D_PC <= 32'd0;
            D_instruction <= 32'd0;
        end else if (!stall) begin
            // If not stalled or flushed, pass the data from IF to ID
            D_PC <= F_PC;
            D_instruction <= F_instruction;
        end else begin
            // If stalled, the register holds its current value
            D_PC <= D_PC;
            D_instruction <= D_instruction;
        end
    end

endmodule
