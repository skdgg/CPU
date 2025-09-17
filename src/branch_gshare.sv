// branch_gshare.sv (XOR hash / GShare)
module branch_gshare (
  input  logic clk,
  input  logic rst,

  // IF: predict
  input  logic [31:0] pc_if,
  output logic        pred_taken_if,
  output logic [7:0]  pht_idx_if,  // carry to EX

  // EX: update
  input  logic        ex_update_en,        // this cycle has a branch-like to train
  input  logic        ex_actual_taken,     // real outcome
  input  logic [7:0]  pht_idx_ex   // index 
);
  //PHT size 256 (2^8)

  // ---- state ----
  logic [1:0]   pht [0:255];   // 2-bit saturating counters
  logic [7:0]   ghr;         // global history
  logic [7:0]   pc_idx;
  // ---- IF: XOR hash = PC_low_N ^ GHR ----
  always_comb begin
    pc_idx           = pc_if[9:2] ^ pc_if[31:24] ;     // ignore [1:0] (word aligned)
    pht_idx_if       = pc_idx ^ ghr;   // <-- XOR hash
    pred_taken_if    = pht[pht_idx_if][1];    // MSB = prediction
  end

  integer i;
  // ---- EX: train PHT & update GHR (non-speculative) ----
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < 256; i++) pht[i] <= 2'b01; // weak-not-taken
      ghr <= 8'd0;
    end else if (ex_update_en) begin
      unique case (ex_actual_taken)
        1'b1: if (pht[pht_idx_ex] != 2'b11) pht[pht_idx_ex] <= pht[pht_idx_ex] + 2'b01;
        1'b0: if (pht[pht_idx_ex] != 2'b00) pht[pht_idx_ex] <= pht[pht_idx_ex] - 2'b01;
      endcase
      // shift in real outcome
      ghr <= { ghr[6:0], ex_actual_taken };
    end
  end
endmodule
