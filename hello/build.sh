#!/bin/bash

# Build script for Verilog simulation and VCD generation

echo "======================================"
echo "Verilog Build and Simulation Script"
echo "======================================"

# Clean up previous build artifacts
echo "Cleaning previous build files..."
rm -f hello_sim hello.vcd

# Compile Verilog files
echo "Compiling Verilog files..."
iverilog -o hello_sim hello.v hello_tb.v

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"

# Run simulation
echo "Running simulation..."
vvp hello_sim

if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed!"
    exit 1
fi

echo "Simulation complete!"

# Check if VCD file was generated
if [ -f "hello.vcd" ]; then
    echo "SUCCESS: VCD file 'hello.vcd' generated successfully!"
    echo "You can now view the waveform using GTKWave or TerosHDL"
else
    echo "WARNING: VCD file was not generated!"
    exit 1
fi

# Prompt to view the waveform with GTKWave
echo "To view the waveform with GTKWave, run the following command:"
echo "gtkwave hello.vcd" 
# prompt user to run the above command to view the waveform
read -p "Press Enter to execute the above command and view the waveform, or Ctrl+C to exit..."
gtkwave hello.vcd

echo "======================================"
