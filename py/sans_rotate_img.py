"""Generate the eight rotating Sans beam frames and their collision masks."""

import math
from pathlib import Path

from PIL import Image

from sans_beam_img import HEIGHT, WIDTH, is_border, rectangles

ROOT = Path(__file__).resolve().parent.parent
CHR = ROOT / "Undertale.chr"
GENERATED_CHR = ROOT / "data" / "SANSROTATE.chr"
INCLUDE = ROOT / "data" / "monsters" / "sans" / "rotate_data.inc"
BANK = 40
FRAMES = 8


def frame_image(index):
    angle = math.pi * index / FRAMES
    cosine, sine = math.cos(angle), math.sin(angle)
    image = Image.new("L", (WIDTH, HEIGHT))
    for y in range(2, HEIGHT - 2):
        for x in range(2, WIDTH - 2):
            dx, dy = x - (WIDTH - 1) / 2, y - (HEIGHT - 1) / 2
            along = dx * cosine + dy * sine
            across = -dx * sine + dy * cosine
            if abs(across) <= 6 + abs(along) * 0.12:
                image.putpixel((x, y), 255)
    return image


def build():
    images = [frame_image(i) for i in range(FRAMES)]
    banks = bytearray()
    for image in images:
        tiles = bytearray()
        for ty in range(HEIGHT // 8):
            for tx in range(WIDTH // 8):
                plane = []
                for y in range(ty * 8, ty * 8 + 8):
                    row = 0
                    for x in range(tx * 8, tx * 8 + 8):
                        row = (row << 1) | bool(is_border(x, y) or image.getpixel((x, y)))
                    plane.append(row)
                tiles.extend(plane + plane)
        banks.extend(tiles.ljust(4096, b"\0"))
    data = bytearray(CHR.read_bytes())
    start = BANK * 4096
    end = start + len(banks)
    if end > len(data):
        raise ValueError("CHR is too small for rotating beam banks")
    previous = GENERATED_CHR.read_bytes() if GENERATED_CHR.exists() else b""
    if any(data[start:end]) and data[start:end] not in (banks, previous):
        raise ValueError("rotating beam banks overlap existing CHR data")

    lines = [f"SANS_ROTATE_BANK = {BANK}", "sans_rotate_map:"]
    for row in range(HEIGHT // 8):
        lines.append("    .byte " + ", ".join(str(row * 17 + x) for x in range(17)))
    for part in ("lo", "hi"):
        prefix = "<" if part == "lo" else ">"
        lines.append(f"sans_rotate_hitbox_{part}:")
        lines.append("    .byte " + ", ".join(f"{prefix}sans_rotate_hitbox_{i}" for i in range(FRAMES)))
    for i, image in enumerate(images):
        lines.append(f"sans_rotate_hitbox_{i}:")
        for rect in rectangles(image):
            lines.append("    .byte " + ", ".join(str(v) for v in rect))
        lines.append("    .byte $FF")
    data[start:end] = banks
    CHR.write_bytes(data)
    GENERATED_CHR.write_bytes(banks)
    INCLUDE.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"Sans rotating beam: {FRAMES} frames in CHR banks {BANK}-{BANK + FRAMES - 1}")


if __name__ == "__main__":
    build()
