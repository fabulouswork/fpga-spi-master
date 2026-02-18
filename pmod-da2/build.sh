#!/bin/bash

# Build script for SPI Master simulation and VCD generation

echo "======================================"
echo "SPI Master Build and Simulation Script"
echo "======================================"

# Clean up previous build artifacts
echo "Cleaning previous build files..."
rm -f spimaster_sim spimaster.vcd

# Compile Verilog files
echo "Compiling Verilog files..."
iverilog -o spimaster_sim spimaster.v spimaster_tb.v

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"

# Run simulation
echo "Running simulation..."
vvp spimaster_sim

if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed!"
    exit 1
fi

echo "Simulation complete!"

# Check if VCD file was generated
if [ -f "spimaster.vcd" ]; then
    echo "SUCCESS: VCD file 'spimaster.vcd' generated successfully!"
    echo "You can now view the waveform using GTKWave or TerosHDL"
    echo "Command: gtkwave spimaster.vcd"
else
    echo "WARNING: VCD file was not generated!"
    exit 1
fi

echo "======================================"
