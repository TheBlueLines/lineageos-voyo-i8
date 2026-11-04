#!/usr/bin/env python3
"""Get a MediaTek XFLASH DA out of an interrupted WRITE_DATA: pad the packet it
is waiting for until it answers, then reboot it. Only boot was being written.
Usage: da_unstick.py COM3"""
import struct
import sys
import time

import serial

MAGIC = 0xFEEEEEEF
port = sys.argv[1]
s = serial.Serial(port, 115200, timeout=0.2, write_timeout=2)
total = 0
got = b""
end = time.time() + 90
zero = bytes(0x4000)
while time.time() < end and not got:
    try:
        s.write(zero)
        total += len(zero)
    except serial.SerialTimeoutException:
        print("write stalled after", total)
    got = s.read(64)
print(f"sent {total:#x} bytes, DA answered: {got[:32].hex()}")
s.reset_input_buffer()
time.sleep(1)
print("left over:", s.read(4096)[:32].hex())


def send(data):
    s.write(struct.pack("<III", MAGIC, 1, len(data)))
    s.flush()
    s.write(data)
    s.flush()


def status():
    t = time.time() + 6
    hdr = b""
    while len(hdr) < 12 and time.time() < t:
        hdr += s.read(12 - len(hdr))
    if len(hdr) < 12:
        return None
    _, _, n = struct.unpack("<III", hdr)
    return s.read(n).hex()


send(struct.pack("<I", 0x010007))  # SHUTDOWN
print("shutdown:", status())
send(struct.pack("<IIIIIIII", 0, 0, 0, 0, 0, 0, 0, 0))
print("params:", status())
