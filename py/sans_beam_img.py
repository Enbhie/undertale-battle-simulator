"""Build Sans beam tiles, tile maps, and collision rectangles from PNG masks."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "data" / "monsters" / "sans"
CHR = ROOT / "Undertale.chr"
GENERATED_CHR = ROOT / "data" / "SANSBEAM.chr"
INCLUDE = ROOT / "data" / "monsters" / "sans" / "beam_data.inc"
BANK = 57
WIDTH, HEIGHT = 136, 64


def load(name):
    image = Image.open(SOURCE / f"beam_{name}.png").convert("L")
    if image.size != (WIDTH, HEIGHT) or any(image.histogram()[1:255]):
        raise ValueError(f"{name}: expected a {WIDTH}x{HEIGHT} black-and-white PNG")
    return image


def is_border(x, y):
    return x < 2 or x >= WIDTH - 2 or y < 2 or y >= HEIGHT - 2


def rectangles(image):
    result = []
    previous = {}
    for y in range(2, HEIGHT - 2, 4):
        end = min(y + 4, HEIGHT - 2)
        occupied = [
            any(image.getpixel((x, row)) for row in range(y, end))
            for x in range(2, WIDTH - 2)
        ]
        x = 0
        current = {}
        while x < len(occupied):
            if not occupied[x]:
                x += 1
                continue
            start = x
            while x < len(occupied) and occupied[x]:
                x += 1
            key = (start + 2, x - start)
            if key in previous:
                index = previous[key]
                rect = result[index]
                result[index] = (rect[0], rect[1], rect[2], rect[3] + end - y)
            else:
                index = len(result)
                result.append((start + 2, y, x - start, end - y))
            current[key] = index
        previous = current
    if len(result) > 32:
        raise ValueError("beam requires more than 32 hitboxes")
    return result


def build():
    images = {name: load(name) for name in ("ring", "cross")}
    tiles = []
    maps = {}
    for name in ("ring", "cross", "empty"):
        for warning in (False, True) if name != "empty" else (False,):
            key = name + ("_warning" if warning else "")
            tilemap = []
            for ty in range(HEIGHT // 8):
                for tx in range(WIDTH // 8):
                    plane = []
                    for y in range(ty * 8, ty * 8 + 8):
                        row = 0
                        for x in range(tx * 8, tx * 8 + 8):
                            border = is_border(x, y)
                            pixel = border or (
                                name != "empty"
                                and images[name].getpixel((x, y))
                                and (not warning or (x + y) % 2 == 0)
                            )
                            row = (row << 1) | bool(pixel)
                        plane.append(row)
                    tile = bytes(plane + plane)
                    if tile not in tiles:
                        tiles.append(tile)
                    tilemap.append(tiles.index(tile))
            maps[key] = tilemap
    if len(tiles) > 256:
        raise ValueError("beam graphics exceed one 4KB CHR bank")

    data = bytearray(CHR.read_bytes())
    start = BANK * 4096
    if len(data) < start + 4096:
        raise ValueError("CHR is too small for the Sans beam bank")
    existing = data[start:start + 4096]
    new = b"".join(tiles).ljust(4096, b"\0")
    previous = GENERATED_CHR.read_bytes() if GENERATED_CHR.exists() else b""
    if any(existing) and existing not in (new, previous):
        raise ValueError("Sans beam bank overlaps existing CHR data")
    data[start:start + 4096] = new

    lines = [f"SANS_BEAM_CHR = ${BANK:02X} + $80", ""]
    for name, tilemap in maps.items():
        lines.append(f"sans_beam_{name}:")
        for pos in range(0, len(tilemap), WIDTH // 8):
            lines.append("    .byte " + ", ".join(f"${v:02X}" for v in tilemap[pos:pos + WIDTH // 8]))
    for name, image in images.items():
        lines.append(f"sans_beam_{name}_hitboxes:")
        for rect in rectangles(image):
            lines.append("    .byte " + ", ".join(str(v) for v in rect))
        lines.append("    .byte $FF")
    CHR.write_bytes(data)
    GENERATED_CHR.write_bytes(new)
    INCLUDE.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"Sans beams: {len(tiles)} tiles in CHR bank {BANK}")


if __name__ == "__main__":
    build()
