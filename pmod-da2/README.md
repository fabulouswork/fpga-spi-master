

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
- create a test bench for Pmod-DA2
- develop master SPI interface module, so it passes the test bench.
- adapt this module to whatever DAC module I can get. 