#!/bin/bash

# Clean script for pmod-da2 folder - removes all build artifacts

echo "======================================"
echo "Cleaning pmod-da2 folder..."
echo "======================================"

# Remove simulation executable
if [ -f "spimaster_sim" ]; then
    echo "Removing spimaster_sim..."
    rm -f spimaster_sim
fi

# Remove VCD waveform files
if [ -f "spimaster.vcd" ]; then
    echo "Removing spimaster.vcd..."
    rm -f spimaster.vcd
fi

# Remove any other common simulation artifacts
rm -f *.vcd
rm -f *.vvp
rm -f *_sim

echo "Clean complete!"
echo "======================================"
