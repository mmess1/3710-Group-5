from machine import ADC, Pin
from time import sleep_ms

# ----- analog inputs -----
pot1 = ADC(28)   # GP28 / ADC2
pot2 = ADC(29)   # GP29 / ADC3

# ----- 9-bit output buses -----
# bus1 bit 0..8 = GP0..GP8
bus1_nums = [0, 1, 2, 3, 4, 5, 6, 7, 8]

# bus2 bit 0..8 = GP9..GP13, GP14, GP15, GP26, GP27
bus2_nums = [9, 10, 11, 12, 13, 14, 15, 26, 27]

bus1 = [Pin(n, Pin.OUT) for n in bus1_nums]
bus2 = [Pin(n, Pin.OUT) for n in bus2_nums]

def write_bus(pins, value):
    for i, p in enumerate(pins):
        p.value((value >> i) & 1)

def smooth(old, new):
    return (3 * old + new) >> 2

p1_filt = 0
p2_filt = 0

while True:
    # 16-bit scaled ADC -> 9-bit value 0..511
    p1 = pot1.read_u16() >> 7
    p2 = pot2.read_u16() >> 7

    # optional smoothing
    p1_filt = smooth(p1_filt, p1)
    p2_filt = smooth(p2_filt, p2)

    # drive both 9-bit buses
    write_bus(bus1, p1_filt)
    write_bus(bus2, p2_filt)

    # optional debug
    #print(p1_filt, p2_filt)

    sleep_ms(4)