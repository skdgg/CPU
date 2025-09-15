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
    logic                 valid;
    logic [TAG_W-1:0]     tag;
    logic [31:0]          target;
  } btb_entry_t;

  btb_entry_t table [ENTRIES];

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
      hit_if    = table[idx_if].valid && (table[idx_if].tag == tag_if);
      target_if = table[idx_if].target;
  end


  // ---------- EX: synchronous write / invalidate ----------
  integer i;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < ENTRIES; i++) table[i].valid <= 1'b0;
    end
    else if (update_en) begin
      table[idx_ex].valid  <= 1'b1;
      table[idx_ex].tag    <= tag_ex;
      table[idx_ex].target <= target_ex;
    end
  end

endmodule
