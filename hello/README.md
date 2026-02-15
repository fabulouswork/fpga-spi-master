# Hello Verilog - TerosHDL Test Project

## Purpose

This is a simple Verilog test project created to demonstrate and test TerosHDL functionality in VS Code. It contains a basic 4-bit counter module with a testbench for simulation and waveform generation.

## Contents

- **hello.v** - Main Verilog module implementing a 4-bit counter
  - Increments on each clock cycle
  - Active-low reset
  
- **hello_tb.v** - Testbench for simulation
  - Generates clock signal (100MHz)
  - Applies reset sequence
  - Creates VCD waveform file for visualization
  
- **build.sh** - Build and simulation script
  - Compiles Verilog files using Icarus Verilog
  - Runs simulation
  - Generates `hello.vcd` waveform file
  
- **clean.sh** - Cleanup script
  - Removes all build artifacts and generated files

## Usage

### Build and Simulate

```bash
./build.sh
```

This will compile the design, run the simulation, and generate the VCD waveform file.

### View Waveforms

After building, you can view the waveforms:
- Right-click on `hello.vcd` in VS Code
- Select TerosHDL's waveform viewer option
- Or use: `gtkwave hello.vcd`

### Clean Build Artifacts

```bash
./clean.sh
```

## TerosHDL Features to Explore

With this project, you can test various TerosHDL features:

1. **Documentation Generation** - Right-click on `hello.v` → TerosHDL: Generate documentation
2. **Linting** - Automatic syntax checking in the Problems panel
3. **Module Hierarchy** - View design hierarchy in TerosHDL sidebar
4. **Waveform Viewing** - Open `.vcd` files directly in VS Code
5. **Code Snippets** - Try TerosHDL's Verilog/VHDL snippets

## Requirements

- Icarus Verilog (`iverilog` and `vvp`)
- TerosHDL extension for VS Code
- Optional: GTKWave for standalone waveform viewing
