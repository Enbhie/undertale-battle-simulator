"""Generate background tiles for Sans's moving horizontal bones."""

from pathlib import Path

from PIL import Image

from sans_beam_img import HEIGHT, WIDTH, is_border

ROOT = Path(__file__).resolve().parent.parent
CHR = ROOT / "Undertale.chr"
GENERATED_CHR = ROOT / "data" / "SANSHBONE.chr"
INCLUDE = ROOT / "data" / "monsters" / "sans" / "hbone_data.inc"
BANK = 33
OFFSETS = (None, -4, -2, 0, 2, 4, 6)


def build():
    image = Image.open(ROOT / "data" / "monsters" / "sans" / "sbone_h.png").convert("L")
    if image.size != (64, 16) or any(image.histogram()[1:255]):
        raise ValueError("horizontal bone must be a 64x16 black-and-white PNG")
    if any(image.getpixel((x, y)) for y in range(6, 16) for x in range(64)):
        raise ValueError("horizontal bone artwork must fit within its six-pixel hitbox")

    tiles = []

    def tile(row, col, left, right):
        plane = []
        for dy in range(8):
            bits = 0
            for dx in range(8):
                x, y = col * 8 + dx, row * 8 + dy
                pixel = is_border(x, y)
                for start, offset in ((2, left), (70, right)):
                    if offset is not None and start <= x < start + 64 and 0 <= dy - offset < 6:
                        pixel |= bool(image.getpixel((x - start, dy - offset)))
                bits = (bits << 1) | bool(pixel)
            plane.append(bits)
        pattern = bytes(plane + plane)
        if pattern not in tiles:
            tiles.append(pattern)
        return tiles.index(pattern)

    lines = [f"SANS_HBONE_CHR = ${BANK:02X} + $80"]
    for kind, row in enumerate((0, 1, 7)):
        for side in range(2):
            lines.append(f"sans_hbone_tiles_{kind}_{side}:")
            for offset in OFFSETS:
                cols = range(8) if side == 0 else range(9, 17)
                values = [tile(row, col, offset if side == 0 else None,
                               offset if side == 1 else None) for col in cols]
                lines.append("    .byte " + ", ".join(f"${v:02X}" for v in values))
        lines.append(f"sans_hbone_center_{kind}:")
        for left in OFFSETS:
            values = [tile(row, 8, left, right) for right in OFFSETS]
            lines.append("    .byte " + ", ".join(f"${v:02X}" for v in values))

    lines.append("sans_hbone_empty:")
    for row in range(HEIGHT // 8):
        lines.append("    .byte " + ", ".join(
            f"${tile(row, col, None, None):02X}" for col in range(WIDTH // 8)))

    if len(tiles) > 256:
        raise ValueError(f"horizontal bones require {len(tiles)} tiles; maximum is 256")
    for part, prefix in (("lo", "<"), ("hi", ">")):
        lines.append(f"sans_hbone_table_{part}:")
        lines.append("    .byte " + ", ".join(
            f"{prefix}sans_hbone_tiles_{kind}_{side}" for kind in range(3) for side in range(2)))
        lines.append(f"sans_hbone_center_{part}:")
        lines.append("    .byte " + ", ".join(
            f"{prefix}sans_hbone_center_{kind}" for kind in range(3)))

    bank = b"".join(tiles).ljust(4096, b"\0")
    data = bytearray(CHR.read_bytes())
    start = BANK * 4096
    if len(data) < start + 4096:
        raise ValueError("CHR is too small for the horizontal bone bank")
    previous = GENERATED_CHR.read_bytes() if GENERATED_CHR.exists() else b""
    if any(data[start:start + 4096]) and data[start:start + 4096] not in (bank, previous):
        raise ValueError("horizontal bone bank overlaps existing CHR data")
    data[start:start + 4096] = bank
    CHR.write_bytes(data)
    GENERATED_CHR.write_bytes(bank)
    INCLUDE.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"Sans horizontal bones: {len(tiles)} tiles in CHR bank {BANK}")


if __name__ == "__main__":
    build()
