import io
import os
import subprocess
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MESEN = os.environ.get("NES_MESEN")


@unittest.skipUnless(MESEN, "set NES_MESEN to the Mesen executable to run emulator tests")
class SansBeamTransitionTests(unittest.TestCase):
    def test_beams_and_expanded_box(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_beam_transition.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        images = {}
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) == 3 and parts[0] == "IMAGE":
                images[parts[1]] = Image.open(io.BytesIO(bytes.fromhex(parts[2]))).convert("RGB")
        self.assertEqual(set(images), {"ring", "cross", "cleared", "expanded"})

        for name in ("ring", "cross"):
            expected = Image.open(ROOT / "data" / "monsters" / "sans" / f"beam_{name}.png").convert("L")
            for y in range(64):
                for x in range(136):
                    if 118 <= x + 64 <= 135 and 153 <= y + 128 <= 169:
                        continue
                    actual = min(images[name].getpixel((x + 64, y + 128))) > 200
                    self.assertEqual(actual, expected.getpixel((x, y)) > 0, (name, x, y))

        for y in range(132, 188):
            for x in range(68, 196):
                if 118 <= x <= 135 and 153 <= y <= 169:
                    continue
                self.assertLess(max(images["cleared"].getpixel((x, y))), 40, (x, y))

        image = images["expanded"]
        for y in (128, 129, 190, 191):
            for x in range(8, 248):
                self.assertGreater(min(image.getpixel((x, y))), 200, (x, y))
        for y in (130, 131, 188, 189):
            for x in range(60, 204):
                self.assertLess(max(image.getpixel((x, y))), 40, (x, y))


if __name__ == "__main__":
    unittest.main()
