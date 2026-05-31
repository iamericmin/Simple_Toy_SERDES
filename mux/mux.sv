// Simple mux

module mux #(
  parameter BITS = 16
)(
  input logic clk,
  input logic n_rst,
  input logic [$clog2(BITS) - 1:0] s,    // selector inputs
  input logic [BITS - 1:0] i,   // signal inputs
  output logic z
);

  always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
      z <= 1'b0;
    end else begin
      z <= i[s];
    end
  end
  
endmodule
