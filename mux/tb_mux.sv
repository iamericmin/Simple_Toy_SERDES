`timescale 1ns/1ps

module mux_tb;

  parameter BITS = 32;

  // 1. Declare local signals to connect to the Design Under Test (DUT)
  logic clk;
  logic n_rst;
  logic [$clog2(BITS) - 1:0] s;
  logic [BITS - 1:0] i;
  logic z;

  // 2. Instantiate the DUT (Design Under Test)
  mux #(BITS) dut (.*);

  // 3. Clock Generation (50MHz clock -> 20ns period)
  initial clk = 0;
  always #(10ns) clk = ~clk;


  int hit_cnt = 0;
  int miss_cnt = 0;

  // 4. Stimulus Generation
  initial begin
    // Optional: Enable wave dumping for EDA Playground EPWave viewer
    $dumpfile("dump.vcd");
    $dumpvars(0, mux_tb);

    // Initialize inputs
    n_rst = 0;
    s = 4'h0;
    i = 0;

    // Hold reset for 2 clock cycles
    @(posedge clk);
    @(posedge clk);
    n_rst = 1; // Release reset
    
    $display("--- Starting MUX Tests ---");

    for (int round=0; round<100; round++) begin
      hit_cnt = 0;
      miss_cnt = 0;
      i = $urandom();
      for (logic[4:0] sel=0; sel<16; sel++) begin
        s = sel[3:0];
        #5ns;
        @(posedge clk);
        $display("Testing s = %d, Random i: %b", s, i);
        if (z === i[s]) begin
          hit_cnt++;
        end else begin
          miss_cnt++;
          $error("Mismatch found at Round %0d, s = %0d! Expected %b, Got %b", round, s, i[s], z);
        end
      end
      $display("=== Round %0d Results ===", round);
      $display("Hits:   %0d", hit_cnt);
      $display("Misses: %0d", miss_cnt);
    end

    #20;
    $display("--- Tests Complete ---");
    $finish;

  end
endmodule
