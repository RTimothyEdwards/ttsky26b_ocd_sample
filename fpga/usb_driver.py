#!/usr/bin/env python3
#
# Driver for charlieplex array project
# This can be used to send UART commands to the project over
# USB from a host computer.

from pyftdi.ftdi import Ftdi
import time
import sys, os
# from pyftdi.spi import SpiController
import pyftdi.serialext
from array import array as Array
import binascii
import struct
from io import StringIO

# Open the USB FTDI device
# This is roundabout but works. . .

s = StringIO()
Ftdi.show_devices(out=s)
devlist = s.getvalue().splitlines()[1:-1]
gooddevs = []
for dev in devlist:
    url = dev.split('(')[0].strip()
    name = '(' + dev.split('(')[1]
    # if name == '(Single RS232-HS)':
    if name == '(Digilent USB Device)' and url.endswith('/2'):
        gooddevs.append(url)
if len(gooddevs) == 0:
    print('Error:  No matching FTDI devices on USB bus!')
    sys.exit(1)
elif len(gooddevs) > 1:
    print('Error:  Too many matching FTDI devices on USB bus!')
    Ftdi.show_devices()
    sys.exit(1)
else:
    print('Success: Found one matching FTDI device at ' + gooddevs[0])

# The project is configured to run at 50MHz and has a divider to set the
# baud rate to 9600 baud.
port = pyftdi.serialext.serial_for_url(gooddevs[0], baudrate=9600)

remap = [ 6,  5,  4,  3,  2,  1,  0,  7,
	 13, 12, 11, 10,  9,  8, 15, 14,
	 20, 19, 18, 17, 16, 23, 22, 21,
	 27, 26, 25, 24, 31, 30, 29, 28,
	 34, 33, 32, 39, 38, 37, 36, 35,
	 41, 40, 47, 46, 45, 44, 43, 42,
	 48, 55, 54, 53, 52, 51, 50, 49]

k = '0'
while (k != 'q'):

    print("\n-----------------------------------\n")
    print("Select option:")
    print("  (1) all on ")
    print("  (2) all off ")
    print("  (3) test! ")
    print("  (4) gradient ")
    print("  (5) progressive ones ")
    print("  (6) progressive zeros ")
    print("  (q) quit")

    print("\n")

    k = input()

    # Implementation:
    # ASCII values starting with 'G' set the LED address to zero + the ASCII value
    # above 'G' (e.g., 'G' = LED 0, 'H' = LED 1, etc., to LED 55).
    # ASCII values '0' to '9' and 'A' to 'F' set the brightness value.
    # If multiple brightness values are given in sequence, then the address auto-
    # increments by 1.

    if k == '1':
        print("Setting all LEDs on")
        # Write 56 bytes
        port.write('GFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF')

    elif k == '2':
        print("Setting all LEDs off")
        # Write 56 bytes
        port.write('G00000000000000000000000000000000000000000000000000000000')

    elif k == '3':
        print("Setting LED test")
        # Set all LEDs off
        port.write('G00000000000000000000000000000000000000000000000000000000')
	# Set LEDs at specific coordinates
        xvals = [2, 5, 2, 5, 1, 2, 3, 4, 5, 6]
        yvals = [1, 1, 2, 2, 4, 5, 5, 5, 5, 4]
        for i in range(0, len(xvals)):
            idx = yvals[i] * 8 + xvals[i]
            c = chr(71 + remap[idx])
            port.write(c + '3')

    elif k == '4':
        print("Setting LED gradient")
        d = '1234567'
        e = 0.0
        for x in range(0, 8):
            for y in range(0, 7):
                idx = y * 8 + x
                c = chr(71 + remap[idx])
                port.write(c + d[y])

    elif k == '5':
        print("Progressive ones")
        for c in remap:
            port.write(chr(71 + c) + 'E')
            time.sleep(0.1)

    elif k == '6':
        print("Progressive zeros")
        for c in remap:
            port.write(chr(71 + c) + '0')
            time.sleep(0.1)

    elif k == 'q':
        print("Exiting...")

    else:
        print('Selection not recognized.\n')

port.close()

