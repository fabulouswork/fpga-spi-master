

[Pmod DA2 Reference](https://digilent.com/reference/pmod/pmodda2/reference-manual?redirect=1)

Functional Description
```
The Pmod DA2 provides two channels of 12-bit Digital-to-Analog conversion, allowing users to achieve a resolution up to about 1mV.
```
So 12 bit gives the user the ability to adjust voltage output between 0-4V.

Interfacing with the Pmod
```
The Pmod DA2 communicates with the host board via an SPI-like protocol. By bringing the Chip Select line to a low voltage state, users may send a series of 16 clock pulses on the Serial Clock line (SCLK). The data is sent out with the most significant bit (MSB) first on the last 12 clock pulses. An example data stream of how the data might look is provided from the TI datasheet below:
```

[![pmodda2_datastream.png](https://digilent.com/reference/_media/pmod/pmod/da2/pmodda2_datastream.png?cache=&w=900&h=303&tok=e8aafd "pmodda2_datastream.png")](https://digilent.com/reference/_media/pmod/pmod/da2/pmodda2_datastream.png?cache= "View original file")

Use jumper wire to connect cmod-s7 to this slave device.

[![PmodDA2 Block Diagram](https://digilent.com/reference/_media/reference/pmod/pmodda2/pmodda2_blockdiagram.png?w=300&tok=df44d0 "PmodDA2 Block Diagram")](https://digilent.com/reference/_detail/reference/pmod/pmodda2/pmodda2_blockdiagram.png?id=pmod%3Apmodda2%3Areference-manual "reference:pmod:pmodda2:pmodda2_blockdiagram.png")

I need a master SPI module that has the following interface:
- slave select
- clock
- MOSI

The master has configurable clock divider.
The master sends data using MSB first approach.
data width is 16 bit, but only the last 12 bits are used.

Interesting, Pmod-DA2 does not really care about SPI mode. And CS lead time is not mentioned either. 


# Follow Up Action
- create a test bench for Pmod-DA2 ✓
- develop master SPI interface module, so it passes the test bench ✓
- adapt this module to whatever DAC module I can get

## Project Files

### Core Modules
- **spimaster.v** - SPI Master module with configurable clock divider
  - 16-bit data transfer (MSB first)
  - Configurable SPI clock divider
  - Simple start/busy handshaking

- **spimaster_top.v** - Top-level FPGA module with controller
  - Instantiates spimaster with stimulus control
  - Four operating modes:
    - **Manual Mode (00)**: User-controlled transfers via button and switches
    - **Auto Pattern Mode (01)**: Automatic cycling through predefined patterns
    - **Ramp Mode (10)**: Incrementing ramp pattern for DAC
    - **Sine Wave Mode (11)**: Sine wave generation using lookup table
  - Button debouncing and edge detection
  - Status LEDs for busy and mode indication
  - Suitable for FPGA deployment

### Testbenches
- **spimaster_tb.v** - Comprehensive testbench for SPI Master
  - Tests various clock dividers and data patterns
  - Verifies timing and data integrity
  - Back-to-back transfer testing

- **spimaster_top_tb.v** - Testbench for top-level module
  - Tests all four operating modes
  - Button press simulation
  - Reset and recovery testing
  - Clock divider verification

### Build Scripts
- **build.sh** - Build and simulate spimaster module
- **build_top.sh** - Build and simulate top-level module with controller
- **clean.sh** - Clean build artifacts

## Usage

### Simulating the SPI Master
```bash
./build.sh
```

### Simulating the Top Module with Controller
```bash
./build_top.sh
```

### Viewing Waveforms
```bash
# For spimaster simulation
gtkwave spimaster.vcd

# For top module simulation
gtkwave spimaster_top.vcd
```

## FPGA Pin Assignments

When deploying to an FPGA board, connect the following signals:

### System Signals
- `clk` - Main clock input (e.g., 50 MHz, 100 MHz)
- `rst_btn` - Reset button (active low)

### Control Inputs
- `mode_sw[1:0]` - Mode selector switches (2 switches)
- `start_btn` - Manual start button (active high)
- `clk_div_sw[3:0]` - Clock divider switches (4 switches)
- `data_sw[7:0]` - Data input switches (8 switches for manual mode)

### Status Outputs
- `led_busy` - Busy status LED
- `led_mode[1:0]` - Mode indicator LEDs (2 LEDs)

### SPI Interface (to Pmod)
- `spi_cs_n` - Chip Select (active low)
- `spi_sclk` - SPI Clock
- `spi_mosi` - Master Out Slave In

## Operating Modes

### Manual Mode (mode_sw = 00)
- Press `start_btn` to initiate SPI transfer
- Data comes from `data_sw[7:0]` (lower 8 bits)
- Control bits (4'h3) are automatically prepended for Pmod DA2

### Auto Pattern Mode (mode_sw = 01)
- Automatically cycles through predefined patterns
- Transfer occurs approximately every 167ms
- Patterns: low/mid/high values, alternating patterns

### Ramp Mode (mode_sw = 10)
- Generates incrementing ramp for DAC output
- Steps by 64 counts each transfer
- Creates sawtooth waveform on DAC output

### Sine Wave Mode (mode_sw = 11)
- Generates sine wave using 64-entry lookup table
- Produces smooth analog waveform on DAC output
- Steps through table at regular intervals 