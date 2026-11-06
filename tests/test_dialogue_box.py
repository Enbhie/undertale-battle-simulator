import csv
import io
import os
import re
import subprocess
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MESEN = os.environ.get("NES_MESEN")


class DialogueLayoutTests(unittest.TestCase):
    def test_pictured_dialogue_fits_the_box(self):
        examples = (
            ("item", "TXT_ITEM_BANDAGE",
             ["* You re-applied the", "  Bandage.", "* You recovered 10 HP!"]),
            ("ember", "TXT_EMBER_CHECK",
             ["* EMBER - ATK 12 DEF 4", "* It burns with patient", "  focus."]),
        )
        for monster, key, expected in examples:
            with (ROOT / "data" / "monsters" / monster / "text.csv").open() as file:
                entries = dict(csv.reader(file, delimiter="\t"))
            lines = re.split(r"<b>", entries[key])
            lines = [re.sub(r"<[^>]+>", "", line) for line in lines]
            self.assertEqual(lines, expected)
            self.assertTrue(all(len(line) <= 28 for line in lines))

    @unittest.skipUnless(MESEN, "set NES_MESEN to the Mesen executable to run emulator tests")
    def test_dialogue_renders_with_intact_borders(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "dialogue_box.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        images = {}
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) == 3 and parts[0] == "IMAGE":
                images[parts[1]] = Image.open(io.BytesIO(bytes.fromhex(parts[2]))).convert("RGB")
        self.assertEqual(set(images), {"bandage", "ember"}, result.stdout)
        self.assertIn("BANDAGE_HP\t15", result.stdout)
        self.assertNotIn("TIMEOUT", result.stdout)
        for name, image in images.items():
            for y in range(128, 192):
                for x in (246, 247):
                    self.assertGreater(min(image.getpixel((x, y))), 200, (name, x, y))
                self.assertLess(max(image.getpixel((248, y))), 40, (name, 248, y))
            for y in (136, 152, 168):
                white_pixels = sum(min(image.getpixel((x, row))) > 200
                                   for row in range(y, y + 8) for x in range(16, 232))
                self.assertGreater(white_pixels, 50, (name, y))


if __name__ == "__main__":
    unittest.main()
