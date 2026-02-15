#!/bin/bash

# Clean script for hello folder - removes all build artifacts

echo "======================================"
echo "Cleaning hello folder..."
echo "======================================"

# Remove simulation executable
if [ -f "hello_sim" ]; then
    echo "Removing hello_sim..."
    rm -f hello_sim
fi

# Remove VCD waveform files
if [ -f "hello.vcd" ]; then
    echo "Removing hello.vcd..."
    rm -f hello.vcd
fi

# Remove any other common simulation artifacts
rm -f *.vcd
rm -f *.vvp
rm -f *_sim

echo "Clean complete!"
echo "======================================"
