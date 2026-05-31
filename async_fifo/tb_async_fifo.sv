// Testbench for async fifo
// Tests async FWFT behavior
// Depth restricted to powers of 2

`timescale 1ns/1ps

module tb_async_fifo;

  parameter WIDTH = 32;
  parameter DEPTH = 8;

  // 1. Declare local signals to connect to the Design Under Test (DUT)
  logic rclk; // read clock
  logic wclk; // write clock
  logic n_rst;
  logic ren; // active low read enable
  logic wen; // active low write enable
  logic [WIDTH - 1:0] din; // data to write to fifo
  logic [WIDTH - 1:0] dout; // data coming out of fifo
  logic empty; // active high fifo empty flag
  logic full; // active high fifo full flag

  async_fifo #(WIDTH, DEPTH) dut (.*);

  // 3. Clock Generation
  // Generate two separate clocks for write and read
  initial begin
    wclk = 0;
    forever #10ns wclk = ~wclk;
  end

  initial begin
    rclk = 0;
    forever #5ns rclk = ~rclk;
  end

  // write driver
  // checks if fifo not full and writes to it
  task write_fifo(input logic [WIDTH-1:0] test_din);
    if (~full) begin // if not full, write
      wen = 0;
      din = test_din;
      @(posedge wclk);
    end else begin // if full, wait
      wen = 1;
      @(posedge wclk);
      $display("FIFO full!");
    end
  endtask

  // read driver
  // checks if fifo not empty and reads from it
  task read_fifo(output logic [WIDTH-1:0] test_dout);
    if (~empty) begin // if not empty, read
      ren = 0;
      @(posedge rclk);
      test_dout = dout;
    end else begin // if empty, wait
      ren = 1;
      @(posedge rclk);
      $display("FIFO empty!");
    end
  endtask

// 4. Stimulus Generation
  initial begin
    logic [WIDTH-1:0] test_data;
    logic [WIDTH-1:0] captured_data;

    int random_w_delay;
    int random_r_delay;

    $dumpfile("dump.vcd");
    $dumpvars(0, tb_async_fifo);
    for (int i = 0; i < DEPTH; i = i + 1) begin
      $dumpvars(0, tb_async_fifo.dut.fifo[i]);
    end

    // Initialize inputs
    n_rst = 0;
    ren   = 1;
    wen   = 1;
    din   = 0;

    // Wait for slower read clock
    repeat(3) @(posedge rclk);
    n_rst = 1; // Release reset
    $display("--- Starting async FIFO Tests ---");

    test_data = 32'd100;

    for (int i=0; i<DEPTH + 10; i++) begin
      write_fifo(test_data);
      $display("Wrote %h to FIFO slot %d!", test_data, i);
      if (~full) begin
        test_data++;
      end
    end

    for (int i=0; i<DEPTH + 10; i++) begin
      read_fifo(captured_data);
      $display("Read %h from FIFO slot %d!", captured_data, i);
    end

    n_rst = 0;
    repeat(3) @(posedge rclk);
    n_rst = 1;

    // Fix 2: Put loops inside the fork, and control time with join_any
    fork
      // Thread 1: Continuous Write Loop
      begin
        forever begin
          // random delay for 0 to 2 clock cycles
          // random_w_delay = $urandom_range(0, 5);
          random_w_delay = 0;
          repeat(random_w_delay) @(posedge wclk);

          write_fifo(test_data);
          // Only increment data if the write actually succeeded (FIFO wasn't full)
          if (~full) begin
            test_data++;
          end
        end
      end

      // Thread 2: Continuous Read Loop
      begin
        forever begin
          // random delay for 0 to 2 clock cycles
          random_r_delay = 0;
          // random_r_delay = $urandom_range(0, 5);
          repeat(random_r_delay) @(posedge rclk);

          read_fifo(captured_data);
          if (~empty) begin
            $display("[%0t ns] RxFIFO Read: %h", $time, captured_data);
          end
        end
      end

      // Thread 3: Simulation Timer (Runs everything for 5000 NANOSECONDS)
      #10000ns;

    join_any // Unblocks the moment the 5000ns timer finishes

    // Fix 3: Kill the infinite 'forever' loops so the simulation can exit
    disable fork; 

    $display("--- Tests Complete! ---");
    $finish;
  end

endmodule