# Altair 8800 on the Ulx3s ECP5 FPGA board

### Introduction

This is an implementation of the Altair 8800 kit computer from 1975.

It is partly based on the [Mister version](https://github.com/MiSTer-devel/Altair8800_Mister) but uses a different CPU implementation (from the [Odysseus project](https://github.com/ulx3s/fpga-odysseus/tree/master/tutorials/07-Computer)), and a different implementation of the front panel, .

The front panel is displayed on an HDMI monitor.

Currently, the leds are implemented on the video output and on the built-in leds and led Pmods. 

Input is via the built-in switches and buttons, and via a 1bitsquared 8-switch Pmod.

You can run Microsoft basic by connecting a serial terminal to /dev/ttyUSB0 at 9600 baud, and entering the J000000 command.
The other Altair 880 turnkey monitor commands are also available.

The implementation does not run on a 12f because of the amount of BRAM used for the background image.

### User interface

Switch 0 is used to set run or step mode.

Button 0 is reset.

Button 1 is single-step

Button 2 is examine.

Button 3 is examine next.

Button 4 is deposit.

Button 5 is deposit next.

The 8 switches on the Pmod are used to set the data or least significant bits of the address.

The sense switches that also set the most significant bits of the address, are not yet implemented.

There is no OSD for loading software yet.

### Bugs

The deposit next switch does not work correctly.

The image quality of the background image is not good.

The icons for up and down switches are not yet implemented.

Not all the status signals are correct. The interrupt ones are not implemented.
