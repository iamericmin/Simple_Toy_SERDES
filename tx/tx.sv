// Simple fifo: standard fifo (no FWFT, one clock cycle minimum delay)
// Restricted to depths of powers of 2
// TODO: add almost full/empty, and overflow/underflow flags

'include "../sr/sr.sv"
'include "../fifo/fifo.sv"

module tx #(
  parameter WIDTH = 8,
  parameter DEPTH = 4
)(
  input logic pclk, // parallel input clock
  input logic sclk, // serial output clock, (pclk * WIDTH) MHz
  input logic n_rst,
  input logic ren, // active low read enable
  input logic wen, // active low write enable
  input logic [WIDTH - 1:0] din, // data to write to fifo
  output logic [WIDTH - 1:0] dout, // data coming out of fifo
  output logic empty, // active high fifo empty flag
  output logic full, // active high fifo full flag
  output logic sout, // serial out from SR
);

  logic [WIDTH - 1:0] fifo_out;
  logic sr_update;
  logic sr_pin;
  logic sr_pout;

  // PISO sr is FBFT (first bit fall through)
  // First bit of parallel input automatically shows on pout[0] upon load
  // So clock SR BITS - 1 times for parallel input of size BITS
  // pulse update every BITS cycles
  // So for word size 8, procedue goes as follows:
    // 1st clock cycle: load word
  sr #(WIDTH) sr (
    .clk(sclk),
    .n_rst(n_rst),
    .en(1'b1),
    .mode(2'b11),
    .update(pclk),
    .pin(sr_pin),
    .pout(sout)
  );
  
  fifo #(WIDTH, DEPTH) fifo (
    .clk(pclk),
    .n_rst(n-rst),
    .ren(ren),
    .wen(wen),
    .din(din),
    .dout(fifo_out),
    .empty(empty),
    .full(full)
  );

  assign sout = 

  always_ff @(posedge clk, n_rst) begin
    
  end
  
endmodule
