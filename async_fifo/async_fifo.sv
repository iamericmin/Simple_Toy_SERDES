// Simple FWFT async fifo
// Restricted to depths of powers of 2

module async_fifo #(
  parameter WIDTH = 16,
  parameter DEPTH = 4
)(
  input logic rclk, // read clock
  input logic wclk, // write clock
  input logic n_rst,
  input logic ren, // active low read enable
  input logic wen, // active low write enable
  input logic [WIDTH - 1:0] din, // data to write to fifo
  output logic [WIDTH - 1:0] dout, // data coming out of fifo
  output logic empty, // active high fifo empty flag
  output logic full // active high fifo full flag
);

  localparam POINTER_WIDTH = $clog2(DEPTH);

  logic [WIDTH - 1:0] fifo [DEPTH - 1:0]; // FIFO memory

  // intermediary signals
  // declared as POINTER_WIDTH in size because grey code requires extra MSB
  logic [POINTER_WIDTH:0] b_wptr; // binary write pointer
  logic [POINTER_WIDTH:0] b_rptr; // binary read pointer

  logic [POINTER_WIDTH:0] g_wptr; // gray code write pointer
  logic [POINTER_WIDTH:0] g_rptr; // gray code read pointer

  logic [POINTER_WIDTH:0] sync_g_wptr; // synchronized gray code write pointer
  logic [POINTER_WIDTH:0] sync_g_rptr; // synchronized gray code read pointer

  logic [POINTER_WIDTH:0] sync_g_wptr_inter; // intermediary signal in 2FF (Danger Zone!)
  logic [POINTER_WIDTH:0] sync_g_rptr_inter; // intermediary signal in 2FF (Danger Zone!)

  // empty flag asserted when synchronized write pointer equals read pointer
  assign empty = (sync_g_wptr == g_rptr);

  // full flag asserted when top two MSB of write pointer is the inverse of the top two MSB of read pointer
  // and if the rest of both are the same
  assign full = (sync_g_rptr[POINTER_WIDTH:POINTER_WIDTH-1] == ~g_wptr[POINTER_WIDTH:POINTER_WIDTH-1]) && (sync_g_rptr[POINTER_WIDTH-2:0] == g_wptr[POINTER_WIDTH-2:0]);

  // write pointer handler
  always_ff @(posedge wclk, negedge n_rst) begin
    if (~n_rst) begin
      b_wptr <= 0;
      g_wptr <= 0;

      // TODO: move this to synchronized reset block later
      for (int i = 0; i < DEPTH; i++) begin
        fifo[i] <= 0;
      end
    end else begin
      if (~wen && ~full) begin // if valid write condition
        // truncate write pointer to proper bit width
        b_wptr <= b_wptr + 1;
        g_wptr <= (b_wptr + 1) ^ ((b_wptr + 1) >> 1); // added 1 to b_wptr to account for non-blocking assignment
        fifo[b_wptr[POINTER_WIDTH - 1:0]] <= din;
      end
    end
  end

  // assign dout combinationally for FWFT behavior
  assign dout = fifo[b_rptr[POINTER_WIDTH - 1:0]];

  // read pointer handler
  always_ff @(posedge rclk, negedge n_rst) begin
    if (~n_rst) begin
      b_rptr <= 0;
      g_rptr <= 0;
    end else begin
      if (~ren && ~empty) begin // if valid read condition
        b_rptr <= b_rptr + 1;
        g_rptr <= b_rptr + 1 ^ (b_rptr + 1 >> 1);
      end
    end
  end

  // 2FF sync for rptr
  always_ff @(posedge wclk, negedge n_rst) begin
    if (~n_rst) begin
      sync_g_rptr_inter <= 0;
      sync_g_rptr <= 0;
    end else begin
      sync_g_rptr_inter <= g_rptr;
      sync_g_rptr <= sync_g_rptr_inter;
    end
  end

  // 2FF sync for wptr
  always_ff @(posedge rclk, negedge n_rst) begin
    if (~n_rst) begin
      sync_g_wptr_inter <= 0;
      sync_g_wptr <= 0;
    end else begin
      sync_g_wptr_inter <= g_wptr;
      sync_g_wptr <= sync_g_wptr_inter;
    end
  end

endmodule
