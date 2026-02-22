#!/bin/bash
# Build script for SPI Master Top Module testbench

echo "Building SPI Master Top Module testbench..."

# Compile the modules
iverilog -o spimaster_top_sim \
    spimaster.v \
    spimaster_top.v \
    spimaster_top_tb.v

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "Running simulation..."
    ./spimaster_top_sim
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "Simulation complete!"
        echo "View waveform with: gtkwave spimaster_top.vcd"
    else
        echo "Simulation failed!"
        exit 1
    fi
else
    echo "Compilation failed!"
    exit 1
fi
