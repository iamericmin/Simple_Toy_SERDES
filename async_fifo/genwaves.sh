iverilog -g2012 -o waves.vvp *.sv && vvp waves.vvp -i +SEED=$(date +%s) && gtkwave dump.vcd --save waves.gtkw
