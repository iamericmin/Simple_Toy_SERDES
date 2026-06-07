// Testbench for async fifo
// Tests async FWFT behavior
// Depth restricted to powers of 2

`timescale 1ns/1ps

module tb_async_fifo;

  parameter WIDTH = 32;
  parameter DEPTH = 8;
  parameter TEST_LEN = 2048;

  // 1. Declare local signals to connect to the Design Under Test (DUT)
  logic rclk; // read clock
  logic wclk; // write clock
  logic r_rst;
  logic w_rst;
  logic ren; // active low read enable
  logic wen; // active low write enable
  logic [WIDTH - 1:0] din; // data to write to fifo
  logic [WIDTH - 1:0] dout; // data coming out of fifo
  logic empty; // active high fifo empty flag
  logic full; // active high fifo full flag

  async_fifo #(WIDTH, DEPTH) dut (.*);

  int seed;

  initial begin
    if (!$value$plusargs("SEED=%d", seed)) begin
      seed = 32'h1; // fallback seed
    end

    $display("Using seed = %0d", seed);

    void'($urandom(seed)); // <-- THIS is what actually seeds RNG
  end

  // 3. Clock Generation
  // Generate two separate clocks for write and read
  // Randomized read/write clock periods between 1ns and 50ns
  int  wclk_half_period;
  int  rclk_half_period;
  real w_freq, r_freq, freq_ratio;

  initial begin
    wclk = 0;
    wclk_half_period = $urandom_range(1, 25);
    // wclk_half_period = 4ns;
    w_freq = (1.0 / (wclk_half_period * 2)) * 1000;
    forever begin
      #(wclk_half_period * 1ns) wclk = ~wclk;
    end
  end

  initial begin
    rclk = 0;
    rclk_half_period = $urandom_range(1, 25);
    // rclk_half_period = 3ns;
    r_freq = (1.0 / (rclk_half_period * 2)) * 1000;
    freq_ratio = r_freq / w_freq;
    forever begin
      #(rclk_half_period * 1ns) rclk = ~rclk;
    end
  end

  // write driver
  // checks if fifo not full and writes to it
  task write_fifo(input logic [WIDTH-1:0] test_din);
    // wait (!full)
    // wen = 0;
    // din = test_din;
    // @(posedge wclk);
    // $display("[%0dns] Wrote %0d to FIFO!", $time, test_din);
    if (~full) begin // if not full, write
      wen = 0;
      din = test_din;
      @(posedge wclk);
      $display("[%0dns] Wrote %0d to FIFO!", $time, test_din);
    end else begin // if full, wait
      wen = 1;
      @(posedge wclk);
      $display("[%0dns] Tried to write %0d, but FIFO was full!", $time, test_din);
    end
  endtask

  // read driver
  // checks if fifo not empty and reads from it
  task read_fifo(output logic [WIDTH-1:0] test_dout);
    wait (!empty);
    ren = 0;
    @(posedge rclk);
    test_dout = dout;
    $display("[%0dns] Read %0d from FIFO!", $time, test_dout);
    // if (~empty) begin // if not empty, read
    //   ren = 0;
    //   @(posedge rclk);
    //   test_dout = dout;
    //   $display("[%0dns] Read %0d from FIFO!", $time, test_dout);
    // end else begin // if empty, wait
    //   ren = 1;
    //   @(posedge rclk);
    //   $display("[%0dns] Tried to read %0d, but FIFO was empty!", $time, test_dout);
    // end
  endtask

// 4. Stimulus Generation
  initial begin
    logic [WIDTH-1:0] test_data;
    logic [WIDTH-1:0] captured_data;

    logic [WIDTH-1:0] bs_input [TEST_LEN]; // TEST_LEN-long array of input bitstreams
    logic [WIDTH-1:0] bs_output [TEST_LEN]; // FIFO output
    int errors = 0;
    
    int random_w_delay;
    int random_r_delay;

    // initialize input bitstreams
    for (int i=0; i<TEST_LEN; i++) begin
      // bs_input[i] = 32'd100 + i;
      bs_input[i] = $urandom();
    end

    $dumpfile("dump.vcd");
    $dumpvars(0, tb_async_fifo);
    for (int i = 0; i < DEPTH; i = i + 1) begin
      $dumpvars(0, tb_async_fifo.dut.fifo[i]);
    end

    // Initialize inputs
    r_rst = 0;
    w_rst = 0;
    ren   = 1;
    wen   = 1;
    din   = 0;

    // Wait for slower read clock
    repeat(3) @(posedge rclk);
    repeat(3) @(posedge wclk);
    r_rst = 1;
    w_rst = 1;
    $display("--- Starting async FIFO Tests ---");

    fork
      // Thread 1: Continuous Write Loop
      begin
        int w_idx = 0;
        while(w_idx < TEST_LEN) begin
          write_fifo(bs_input[w_idx]);
          if (~full) begin
            w_idx = w_idx + 1;
          end
        end
        $display("Write thread done!");
      end

      // Thread 2: Continuous Read Loop
      begin
        int r_idx = 0;
        logic [WIDTH-1:0] read_data;
        while(r_idx < TEST_LEN) begin
          read_fifo(bs_output[r_idx]);
          if (~empty) begin
            r_idx = r_idx + 1;
          end
        end
      end
    join

    // 5. Post-test Verification/Self-Checking
    $display("--- Analyzing Results ---");
    for (int i = 0; i < TEST_LEN; i++) begin
      if (bs_input[i] !== bs_output[i]) begin
        $display("ERROR at index %0d: Expected %0d, Got %0d", i, bs_input[i], bs_output[i]);
        errors++;
      end
    end

    if (errors == 0) begin
      $display("\033[0;32m"); 
      $display("\n********************************************************\n");
      $display("SUCCESS: All %0d bitstream elements matched perfectly!", TEST_LEN);
      $display("RCLK: %.2fMHz / WCLK: %.2fMHZ", r_freq, w_freq);
      $display("R/W clock ratio: %.4f", freq_ratio);
      $display("\n********************************************************\n");
      $display("\033[0m"); 
    end else begin
      $display("\033[0;31m"); 
      $display("\n********************************************************\n");
      $display("FAILURE: %0d mismatches detected.", errors);
      $display("RCLK: %.2fMHz / WCLK: %.2fMHZ", r_freq, w_freq);
      $display("R/W clock ratio: %.4f", freq_ratio);
      $display("\n********************************************************\n");
      $display("\033[0m"); 
    end

    $display("--- Tests Complete! ---");
    $finish;
  end

endmodule