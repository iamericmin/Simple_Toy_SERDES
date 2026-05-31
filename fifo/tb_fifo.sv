// Testbench for simple standard fifo
// No FWFT, one clock cycle minimum delay
// Depth restricted to powers of 2

`timescale 1ns/1ps

module tb_fifo;

  parameter WIDTH = 32;
  parameter DEPTH = 16;

  // 1. Declare local signals to connect to the Design Under Test (DUT)
  logic clk;
  logic n_rst;
  logic ren; // active low read enable
  logic wen; // active low write enable
  logic [WIDTH - 1:0] din; // data to write to fifo
  logic [WIDTH - 1:0] dout; // data coming out of fifo
  logic empty; // active high fifo empty flag
  logic full; // active high fifo full flag
  logic overflow; // active high overflow flag

  fifo #(WIDTH, DEPTH) dut (.*);

  // 3. Clock Generation (50MHz clock -> 20ns period)
  initial clk = 0;
  always #10ns clk = ~clk;

  task test_fifo(
    input logic [WIDTH-1:0] test_din,
    input logic test_ren,
    input logic test_wen
  );
    begin
      din = test_din;
      ren = test_ren;
      wen = test_wen;
      if (~test_ren && test_wen) begin // if reading
        @(posedge clk);
        $display("Read %h from FIFO!", dout);
      end else if (test_ren && ~test_wen) begin // if writing
        @(posedge clk);
        $display("Wrote %h to FIFO!", din);
      end else if (~test_ren && ~test_wen) begin // if reading and writing
        @(posedge clk);
        $display("Wrote %h to FIFO, and read %h at the same time!", din, dout);
      end
      if (full) $display("FIFO full!!!");
      if (empty) $display("FIFO empty!!!");
    end
  endtask

  // 4. Stimulus Generation
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_fifo);
    for (int i = 0; i < DEPTH; i = i + 1) begin
      $dumpvars(0, tb_fifo.dut.fifo[i]);
    end

    // Initialize inputs
    n_rst = 0;
    ren = 1;
    wen = 1;

    // Hold reset for 2 clock cycles
    @(posedge clk);
    @(posedge clk);
    n_rst = 1; // Release reset
    $display("--- Starting FIFO Tests ---");

    // fill FIFO up
    test_fifo(32'hDEADBEEF, 1, 0);
    test_fifo(32'h1337C0DE, 1, 0);
    test_fifo(32'hBABEBABE, 1, 0);
    test_fifo(32'hBEEFC0DE, 1, 0);

    // read FIFO till empty
    for (int i=0; i<DEPTH; i++) begin
      test_fifo(0, 0, 1);
    end

    // fill FIFO up by two
    test_fifo(32'hFF00_FF00, 1, 0);
    test_fifo(32'h00FF_00FF, 1, 0);

    // simultaneous R/W on non-empty FIFO
    test_fifo(32'hDEADBEEF, 0, 0);
    test_fifo(32'h1EE7C0DE, 0, 0);
    test_fifo(32'hDEADBABE, 0, 0);
    test_fifo(32'hBEEFC0DE, 0, 0);
    test_fifo(32'hFF00_FF00, 0, 0);
    test_fifo(32'h00FF_00FF, 0, 0);

    // read FIFO till empty
    for (int i=0; i<DEPTH; i++) begin
      test_fifo(0, 0, 1);
    end

    // simultaneous R/W on empty FIFO
    test_fifo(32'hDEADBEEF, 0, 0);
    test_fifo(32'h1EE7C0DE, 0, 0);
    test_fifo(32'hDEADBABE, 0, 0);
    test_fifo(32'hBEEFC0DE, 0, 0);
    test_fifo(32'hFF00_FF00, 0, 0);
    test_fifo(32'h00FF_00FF, 0, 0);
 
    // fill FIFO up till full
    test_fifo(32'hDEADBEEF, 1, 0);
    test_fifo(32'h1337C0DE, 1, 0);
    test_fifo(32'hBABEBABE, 1, 0);
    test_fifo(32'hBEEFC0DE, 1, 0);

    // Write to full FIFO
    test_fifo(32'h00000000, 1, 0);
    test_fifo(32'hFFFFFFFF, 1, 0);
    test_fifo(32'h00000000, 1, 0);
    test_fifo(32'hFFFFFFFF, 1, 0);

    // simultaneous R/W on full FIFO
    test_fifo(32'hFF00FF00, 0, 0);
    test_fifo(32'h00FF00FF, 0, 0);
    test_fifo(32'hABCDABCD, 0, 0);
    test_fifo(32'hDEADBEEF, 0, 0);
    test_fifo(32'h11110000, 0, 0);
    test_fifo(32'h11001100, 0, 0);
    test_fifo(32'hABCDEF00, 0, 0);
    test_fifo(32'h00001111, 0, 0);

    // read FIFO till empty
    for (int i=0; i<DEPTH; i++) begin
      test_fifo(0, 0, 1);
    end

    // read empty FIFO
    for (int i=0; i<8; i++) begin
      test_fifo(0, 0, 1);
    end

    // fill up FIFO by two
    test_fifo(32'hDEADBEEF, 1, 0);
    test_fifo(32'h1EE7C0DE, 1, 0);

    // read one
    test_fifo(0, 0, 1);

    // write one
    test_fifo(32'hF0F0F0F0, 1, 0); // FIFO should now have 1EE7C0DE and F0F0F0F0, in that order
    
    // simultaneous R/W
    test_fifo(32'hCAFEBABE, 0, 0); // FIFO should now have F0F0F0F0 and CAFEBABE, in that order

    // read two
    test_fifo(0, 0, 1);
    test_fifo(0, 0, 1);

    // fill up FIFO by two
    test_fifo(32'hDEADBEEF, 1, 0);
    test_fifo(32'h1EE7C0DE, 1, 0);

    // Reset
    n_rst = 0;
    @(posedge clk);
    n_rst = 1;

    // write one word to empty FIFO
    test_fifo(32'hDEADBEEF, 1, 0);

    // immediately read it back
    test_fifo(0, 0, 1);


    $display("--- Tests Complete! ---");
    $finish;
  end

endmodule
