import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("sans_beam_img", ROOT / "py" / "sans_beam_img.py")
beams = importlib.util.module_from_spec(spec)
spec.loader.exec_module(beams)


class SansBeamTests(unittest.TestCase):
    def test_graphics_and_collision_cover_both_patterns(self):
        for name in ("ring", "cross"):
            with self.subTest(pattern=name):
                image = beams.load(name)
                rects = beams.rectangles(image)
                self.assertLessEqual(len(rects), 32)
                for y in range(2, beams.HEIGHT - 2):
                    for x in range(2, beams.WIDTH - 2):
                        if image.getpixel((x, y)):
                            self.assertTrue(
                                any(rx <= x < rx + w and ry <= y < ry + h for rx, ry, w, h in rects),
                                (name, x, y),
                            )
                self.assertTrue(all(any(image.getpixel((x, y)) for x in range(2, 134))
                                    for y in (2, 61)))
                self.assertTrue(all(any(image.getpixel((x, y)) for y in range(2, 62))
                                    for x in (2, 133)))

    def test_safe_regions(self):
        ring = beams.rectangles(beams.load("ring"))
        cross = beams.rectangles(beams.load("cross"))
        def hits(rects, x, y):
            return any(rx <= x < rx + w and ry <= y < ry + h for rx, ry, w, h in rects)
        self.assertFalse(hits(ring, 68, 32))
        for point in ((68, 5), (68, 58), (5, 32), (130, 32)):
            self.assertFalse(hits(cross, *point), point)
        self.assertTrue(hits(cross, 68, 32))

    def test_rom_contains_generated_beam_bank(self):
        chr_data = (ROOT / "Undertale.chr").read_bytes()
        generated = (ROOT / "data" / "SANSBEAM.chr").read_bytes()
        self.assertEqual(len(generated), 4096)
        self.assertEqual(chr_data[57 * 4096:58 * 4096], generated)
        source = (ROOT / "data" / "monsters" / "sans" / "beam_data.inc").read_text()
        assembled = (ROOT / "asm" / "data" / "m_4" / "beam_data.inc").read_text()
        self.assertEqual("".join(source.split()), "".join(assembled.split()))


if __name__ == "__main__":
    unittest.main()
