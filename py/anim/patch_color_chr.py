"""Place generated color sprite banks into unused space in the merged CHR."""

import argparse
from pathlib import Path


parser = argparse.ArgumentParser()
parser.add_argument("chr", type=Path, help="merged CHR file")
parser.add_argument("sprites", type=Path, help="generated color sprite CHR")
parser.add_argument("bank", type=int, help="first 1KB sprite bank")
args = parser.parse_args()

data = bytearray(args.chr.read_bytes())
sprites = args.sprites.read_bytes()
start = args.bank * 1024
end = start + len(sprites)
if args.bank < 0 or not sprites or len(sprites) % 1024 or end > len(data):
    parser.error("color sprite data must fit in complete 1KB CHR banks")
if any(data[start:end]):
    parser.error("color sprite banks overlap existing CHR data")
data[start:end] = sprites
args.chr.write_bytes(data)
