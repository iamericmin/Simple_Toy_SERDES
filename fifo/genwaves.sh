iverilog -g2012 -o waves.vvp *.sv && vvp waves.vvp && gtkwave dump.vcd --save waves.gtkw
