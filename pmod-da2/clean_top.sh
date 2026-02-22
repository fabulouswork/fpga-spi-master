#!/bin/bash

# Clean script for SPI Master Top Module - removes build artifacts

echo "======================================"
echo "Cleaning SPI Master Top Module..."
echo "======================================"

# Remove simulation executable
if [ -f "spimaster_top_sim" ]; then
    echo "Removing spimaster_top_sim..."
    rm -f spimaster_top_sim
fi

# Remove VCD waveform file
if [ -f "spimaster_top.vcd" ]; then
    echo "Removing spimaster_top.vcd..."
    rm -f spimaster_top.vcd
fi

# Remove any iverilog temporary files
rm -f *.vvp

echo "Clean complete!"
echo "======================================"
