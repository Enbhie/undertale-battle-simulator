import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATOR = ROOT / "py" / "anim" / "bw_sprimg2chr.py"
PATCHER = ROOT / "py" / "anim" / "patch_color_chr.py"


class ColorSpriteChrTests(unittest.TestCase):
    def test_strike_assets_are_generated_and_referenced(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            args = [
                sys.executable, str(GENERATOR), str(ROOT / "data" / "monsters"),
                "-d", str(path / "sprites.bin"), "-b", "64",
                "-bs", str(ROOT / "data" / "BKGANIM.chr"),
                "-cf", str(path / "constants.asm"), "-c", str(path / "sprites.chr"),
            ]
            missing = subprocess.run(args, capture_output=True, text=True)
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn("require --colorchrfile and --colorbnk", missing.stderr)

            subprocess.run(
                args + ["-cc", str(path / "color.chr"), "-cb", "128"], check=True
            )
            generated = (path / "sprites.bin").read_bytes()
            self.assertEqual(generated, (ROOT / "asm" / "data" / "img_spr.bin").read_bytes())
            self.assertEqual(
                (path / "color.chr").read_bytes(),
                (ROOT / "data" / "COLORSPRANIM.chr").read_bytes(),
            )
            self.assertTrue(any((path / "color.chr").read_bytes()))

    def test_patch_rejects_overlaps_and_out_of_bounds(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            merged = path / "merged.chr"
            color = path / "color.chr"
            merged.write_bytes(bytes(2048))
            color.write_bytes(bytes([42]) * 1024)
            args = [sys.executable, str(PATCHER), str(merged), str(color), "1"]
            subprocess.run(args, check=True)
            self.assertEqual(merged.read_bytes(), bytes(1024) + color.read_bytes())
            overlap = subprocess.run(args, capture_output=True, text=True)
            self.assertNotEqual(overlap.returncode, 0)
            self.assertIn("overlap", overlap.stderr)
            out_of_bounds = subprocess.run(args[:-1] + ["2"], capture_output=True, text=True)
            self.assertNotEqual(out_of_bounds.returncode, 0)
            self.assertIn("must fit", out_of_bounds.stderr)


if __name__ == "__main__":
    unittest.main()
