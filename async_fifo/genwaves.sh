iverilog -g2012 -o waves.vvp *.sv && vvp waves.vvp -i && gtkwave dump.vcd --save waves.gtkw
