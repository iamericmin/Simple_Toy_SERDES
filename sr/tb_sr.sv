`timescale 1ns/1ps

module sr_tb;
  parameter BITS = 8;

  // 1. Declare local signals to connect to the Design Under Test (DUT)
  logic clk;
  logic n_rst;
  logic en;
  logic [1:0] mode;
  logic update;
  logic [BITS - 1:0] pin;
  logic [BITS - 1:0] pout;

  typedef enum logic [1:0] {
    SIPO_RIGHT = 2'b00,
    SIPO_LEFT  = 2'b01,
    PISO_RIGHT = 2'b10,
    PISO_LEFT  = 2'b11
  } mode_t;

  mode_t mode_enum;
  assign mode_enum = mode_t'(mode);

  sr #(BITS) dut (.*);

  // 3. Clock Generation (50MHz clock -> 20ns period)
  initial clk = 0;
  always #10ns clk = ~clk;

  task test_sr(
    input int clocks,
    input logic [1:0] test_mode
  );
    begin
      if (test_mode[1]) begin // if PISO
        $display("--- Starting PISO Test for %0d cycles ---", clocks);
        mode = test_mode;
        pin = $urandom();
        update = 1'b0; 
        @(posedge clk);
        #1ns;
        $display("Loaded bitstream into DUT: %b", pin);
        update = 1'b1;
        #1ns;

        for (int i = 0; i < clocks; i++) begin
          $display("Cycle %0d: Shifted serial bit = %b", i+1, pout[0]);
          @(posedge clk);
          #1ns;
        end
      end else begin // if SIPO
        $display("--- Starting SIPO Test for %0d cycles ---", clocks);
        mode = test_mode;
        update = 1'b1;
    
        for (int i = 0; i < clocks; i++) begin
          pin[0] = $urandom_range(0, 1);
          $display("Cycle %0d: Injecting serial bit = %b", i+1, pin[0]);
          @(posedge clk);
          #1ns;
        end
        
        update = 1'b0;
        @(posedge clk);
        #1ns;
        
        $display("Resulting pout after update: %b", pout);
        update = 1'b1;
      end
    end
  endtask

  // 4. Stimulus Generation
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sr_tb);

    // Initialize inputs
    n_rst = 0;
    en = 1;
    mode = 2'b11; // SIPO, right shift
    update = 1;

    // Hold reset for 2 clock cycles
    @(posedge clk);
    @(posedge clk);
    n_rst = 1; // Release reset
    pin = 0;
    en = 0;    // Enable DUT
    
    $display("--- Starting SR Tests ---");

    // // Test SIPO Right Shift
    // test_sr(BITS, 2'b00);

    // // Test SIPO Left Shift
    // test_sr(BITS, 2'b01);

    // // Test PISO Right Shift
    // test_sr(BITS, 2'b10);

    // // Test PISO Left Shift
    // test_sr(BITS, 2'b11);

    // more PISO tests for later implementation in toy SERDES
    // Used to test first bit fall through
    // Clock BITS - 1 times for parallel input of size BITS
    pin = 8'b11110000;
    update = 1'b0; 
    @(posedge clk);
    $display("Loaded %b!", pin);
    update = 1'b1;
    for (int i = 0; i < BITS-1; i++) begin
      $display("Cycle %0d: Shifted serial bit = %b", i+1, pout[0]);
      @(posedge clk);
    end
    pin = 8'b01011010;
    update = 1'b0; 
    @(posedge clk);
    $display("Loaded %b!", pin);
    update = 1'b1;
    for (int i = 0; i < BITS-1; i++) begin
      $display("Cycle %0d: Shifted serial bit = %b", i+1, pout[0]);
      @(posedge clk);
    end
    pin = 8'b10101010;
    update = 1'b0; 
    @(posedge clk);
    $display("Loaded %b!", pin);
    update = 1'b1;
    for (int i = 0; i < BITS-1; i++) begin
      $display("Cycle %0d: Shifted serial bit = %b", i+1, pout[0]);
      @(posedge clk);
    end

    // End simulation
    #40ns;
    $display("--- Tests Complete ---");
    $finish;
  end

endmodule