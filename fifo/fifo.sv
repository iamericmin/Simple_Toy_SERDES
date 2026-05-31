// Simple FWFT fifo
// Restricted to depths of powers of 2
// Behavior in detail:
  // First Word Fall-Through: if FIFO empty, first written word immediately shows on dout
  // subsequent writes shown only when REN asserted (active low)
  // When simultaneously reading and writing to empty FIFO, FIFO acts as combinational passthrough
  // Therefore, takes DEPTH cycles to fill up, and DEPTH-1 cycles to read full FIFO
// TODO: add almost full/empty, and overflow/underflow flags

module fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 4
)(
  input logic clk,
  input logic n_rst,
  input logic ren, // active low read enable
  input logic wen, // active low write enable
  input logic [WIDTH - 1:0] din, // data to write to fifo
  output logic [WIDTH - 1:0] dout, // data coming out of fifo
  output logic empty, // active high fifo empty flag
  output logic full, // active high fifo full flag
  output logic overflow // active high overflow flag
);

  logic [WIDTH - 1:0] fifo [DEPTH - 1:0]; // FIFO memory

  logic [$clog2(DEPTH) - 1:0] wptr; // write pointer
  logic [$clog2(DEPTH) - 1:0] rptr; // read pointer
  logic [$clog2(DEPTH):0] count; // number of words used in fifo

  logic [WIDTH - 1:0] n_dout;

  assign full = (count == DEPTH);
  assign empty = (count == 0);
  assign dout = (empty && ~(~wen && ~ren)) ? 0 : fifo[rptr];

  always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
      for (int i = 0; i < DEPTH; i++) begin
        fifo[i] <= 0;
      end
      wptr <= 0;
      rptr <= 0;
      count <= 0;
      overflow <= 0;
      // n_dout <= 0;
    end else begin
      if (~wen && ~full && ren) begin // if writing and fifo is not full, and if not reading
        fifo[wptr] <= din;
        wptr <= (wptr == DEPTH - 1) ? 0 : wptr + 1;
        count <= count + 1;
      end else if (~ren && ~empty && wen) begin // if reading and fifo is not empty, and if not writing
        // n_dout <= fifo[rptr];
        rptr <= (rptr == DEPTH - 1) ? 0 : rptr + 1;
        count <= count - 1;
      end else if (~wen && ~ren) begin // simultaneous read and write
        // n_dout <= fifo[rptr];
        if (empty) begin // if empty, don't mess with pointers
          fifo[wptr] <= din;
        end else begin
          fifo[wptr] <= din;
          wptr <= (wptr == DEPTH - 1) ? 0 : wptr + 1;
          rptr <= (rptr == DEPTH - 1) ? 0 : rptr + 1;
        end
      end
    end
  end
  
endmodule
