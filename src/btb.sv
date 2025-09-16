// btb.sv — Direct-mapped Branch Target Buffer
module btb (
  input  logic clk,
  input  logic rst,

  // ==== IF: query ====
  input  logic [31:0] pc_if,       // fetch PC this cycle
  output logic        hit_if,      // 1 = found a target for pc_if
  output logic [31:0] target_if,   // predicted target

  // ==== EX ====
  input  logic        update_en,   // assert when a taken branch/jal/jalr is resolved
  input  logic [31:0] pc_ex,       // PC of the branch being updated
  input  logic [31:0] target_ex  // its actual target address
);

  localparam int ENTRIES = 256;
  // ---------- Derived widths ----------
  localparam int IDX_W = $clog2(ENTRIES);
  // tag excludes index bits [IDX_W+1:2] and byte bits [1:0]
  localparam int TAG_W = 32 - (IDX_W + 2);

  // ---------- Entry definition ----------
  typedef struct packed {
    logic [TAG_W-1:0]     tag;
    logic [31:0]          target;
  } btb_line_t;

  btb_line_t btb_data [ENTRIES];
  logic [ENTRIES-1:0] btb_valid;
  
  // ---------- Index & Tag split ----------
  logic [IDX_W-1:0] idx_if;
  logic [TAG_W-1:0] tag_if;

  logic [IDX_W-1:0] idx_ex;
  logic [TAG_W-1:0] tag_ex;

  always_comb begin
    idx_if = pc_if[IDX_W+1:2];
    tag_if = pc_if[31:IDX_W+2];

    idx_ex = pc_ex[IDX_W+1:2];
    tag_ex = pc_ex[31:IDX_W+2];
  end

  // ---------- IF: combinational read ----------
  always_comb begin
      hit_if    = btb_valid[idx_if] && (btb_data[idx_if].tag == tag_if);
      target_if = hit_if ? btb_data[idx_if].target : 32'b0;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      btb_valid <= 256'd0;     
    end else if (update_en) begin
      btb_valid[idx_ex] <= 1'b1;
    end
  end
  
  // ---------- EX: synchronous write ----------
  always_ff @(posedge clk) begin
    if (update_en) begin
      btb_data[idx_ex].tag    <= tag_ex;
      btb_data[idx_ex].target <= target_ex;
    end
  end


endmodule
