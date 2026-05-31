// universal shift register
// supports PISO and bidirectional SIPO
// PISO mode: loads pin into int_reg if update = 0, and shifts bits if update = 1.
// SIPO mode: shifts bits every clock cycle regardless of update, and loads int_reg to pout if update = 0
// PISO mode: loading pin automatically puts first bit on pout[0]
  // 1st clock cycle: load pin into internal register, pout[0] shows first bit
  // 2nd to BITS clock cycles: rest of pin output to pout[0]
  // This means you clock BITS - 1 times for each pin of size BITS

module sr #(parameter BITS=16) (
  input logic clk,
  input logic n_rst,
  input logic en, // active-low enable
  input logic [1:0] mode, // mode: MSB decides PISO/SIPO (0 for SIPO, 1 for PISO), LSB decides left or right shift (0 for right, 1 for left)
  input logic update, // When low, capture parallel inputs into internal register if PISO, and set parallel outputs to internal register if SIPO
  input logic [BITS - 1:0] pin,	// 16-bit parallel input. LSB is used for input in SIPO mode.
  output logic [BITS - 1:0] pout	// 16-bit parallel output. LSB is used for output in PISO mode.
);
  
  logic [BITS - 1:0] int_reg; // internal register
  logic [BITS - 1:0] n_pout;

  always_comb begin
    if (~en) begin
      if (mode[1]) begin // PISO
        // We use pout[0] as the serial output pin
        // n_pout[0] = int_reg[MSB] if left shift, else int_reg[LSB] if right shift
        // n_pout[BITS - 1:1] padded with 0s
        pout = mode[0] ? {{(BITS-1){1'b0}}, int_reg[BITS - 1]} : {{ (BITS-1){1'b0} }, int_reg[0]};
      end else begin // SIPO
        pout = n_pout;
      end
    end else begin
      pout = 0;
    end
  end

  always_ff @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
      int_reg <= 0;
      n_pout <= 0;
    end else if (~en) begin
      if (mode[1]) begin // PISO
        if (~update) begin // capture parallel inputs into internal register
          int_reg <= pin;
        end else begin
          if (mode[0]) begin // left shift
            int_reg <= {int_reg[BITS - 2:0], 1'b0};
          end else begin // right shift
            int_reg <= {1'b0, int_reg[BITS - 1:1]};
          end
        end
      end else begin // SIPO
        if (~update) begin
          n_pout <= int_reg;
        end
        if (mode[0]) begin // left shift
          int_reg <= {int_reg[BITS - 2:0], pin[0]};
        end else begin // right shift
          int_reg <= {pin[0], int_reg[BITS - 1:1]};
        end
      end
    end
  end
  
endmodule
