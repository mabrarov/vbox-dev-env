import struct, time, sys

with open(sys.argv[1], "wb") as fout:
    fout.write(struct.pack(">q", -(int(time.time())*1000+1)))
