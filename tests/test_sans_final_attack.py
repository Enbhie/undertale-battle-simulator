import importlib.util
import io
import math
import os
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "py"))
spec = importlib.util.spec_from_file_location("sans_rotate_img", ROOT / "py" / "sans_rotate_img.py")
rotation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rotation)
MESEN = os.environ.get("NES_MESEN")


class FinalBeamAssetTests(unittest.TestCase):
    def test_horizontal_bone_graphics_bank(self):
        bank = (ROOT / "data" / "SANSHBONE.chr").read_bytes()
        self.assertEqual(len(bank), 4096)
        rom_chr = (ROOT / "Undertale.chr").read_bytes()
        self.assertEqual(rom_chr[33 * 4096:34 * 4096], bank)

    def test_rotating_frames_and_hitboxes(self):
        banks = (ROOT / "data" / "SANSROTATE.chr").read_bytes()
        self.assertEqual(len(banks), rotation.FRAMES * 4096)
        rom_chr = (ROOT / "Undertale.chr").read_bytes()
        self.assertEqual(rom_chr[rotation.BANK * 4096:(rotation.BANK + rotation.FRAMES) * 4096], banks)
        for i in range(rotation.FRAMES):
            image = rotation.frame_image(i)
            rects = rotation.rectangles(image)
            self.assertLessEqual(len(rects), 32)
            self.assertTrue(any(image.getpixel((x, y))
                                for y in range(26, 38) for x in range(62, 74)))
            for y in range(2, 62):
                for x in range(2, 134):
                    if image.getpixel((x, y)):
                        self.assertTrue(any(rx <= x < rx + w and ry <= y < ry + h
                                            for rx, ry, w, h in rects), (i, x, y))


@unittest.skipUnless(MESEN, "set NES_MESEN to the Mesen executable to run emulator tests")
class FinalAttackEmulatorTests(unittest.TestCase):
    def test_horizontal_bone_rendering(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_hbone_render.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        self.assertIn("DONE", result.stdout)
        self.assertNotIn("TIMEOUT", result.stdout)
        frames = {}
        source = Image.open(ROOT / "data" / "monsters" / "sans" / "sbone_h.png").convert("L")
        crossing = set()
        dialogue = None
        for line in result.stdout.splitlines():
            parts = line.split()
            if parts and parts[0] == "DIALOGUE":
                dialogue = Image.open(io.BytesIO(bytes.fromhex(parts[1]))).convert("RGB")
            if not parts or parts[0] != "SNAP":
                continue
            stage, time, left, right = map(int, parts[1:5])
            frames[stage, time] = (left, right)
            # The main-loop packet queue and PPU display have a three-frame pipeline.
            if (stage, time - 3) not in frames:
                continue
            left, right = frames[stage, time - 3]
            if left >= 0 and right >= 0 and abs(left - right) < 6:
                crossing.add(stage)
            image = Image.open(io.BytesIO(bytes.fromhex(parts[5]))).convert("RGB")
            for y in range(128, 192):
                for x in range(64, 200):
                    # The SOUL is deliberately on the same scanlines as the bones.
                    if 118 <= x <= 148 and 145 <= y <= 174:
                        continue
                    expected = x < 66 or x >= 198 or y < 130 or y >= 190
                    for bx, by in ((66, left), (134, right)):
                        if by >= 0 and bx <= x < bx + 64 and by <= y < by + 6:
                            expected |= bool(source.getpixel((x - bx, y - by)))
                    actual = min(image.getpixel((x, y))) > 200
                    self.assertEqual(actual, expected, (stage, time, left, right, x, y))
        self.assertEqual(crossing, {1, 2})
        self.assertEqual(len(frames), 232)
        self.assertIsNotNone(dialogue)
        for x in (*range(64, 72), *range(192, 200)):
            for y in (*range(130, 136), *range(184, 190)):
                self.assertLess(max(dialogue.getpixel((x, y))), 200, (x, y))
            for y in (128, 129, 190, 191):
                self.assertGreater(min(dialogue.getpixel((x, y))), 200, (x, y))

    def test_horizontal_bones_move_in_opposite_directions(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_horizontal_bones.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        reports = [line.split() for line in result.stdout.splitlines()
                   if line.startswith("HORIZONTAL")]
        self.assertEqual(len(reports), 2, result.stdout)
        for stage, report in enumerate(reports, 1):
            self.assertEqual(int(report[1]), stage)
            self.assertGreater(int(report[2]), 3)
            self.assertGreater(int(report[3]), 3)
            self.assertEqual(report[4:7], ["1", "1", "0"])
            self.assertGreater(int(report[7]), 0)
            self.assertGreater(int(report[8]), 0)
            self.assertGreater(int(report[9]), 0)
            for distance, moves in ((int(report[10]), int(report[2])),
                                    (int(report[11]), int(report[3]))):
                self.assertAlmostEqual(distance / moves, 1.5, delta=0.1)
        self.assertNotIn("TIMEOUT", result.stdout)

    def test_first_strike_after_normal_boss_progression(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_progression_strike.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        for fight in (2, 3, 4):
            self.assertIn(f"FIRST_STRIKE\t{fight}\t0\t127", result.stdout)
        self.assertIn("SANS_TURN\t1\t1", result.stdout)
        self.assertNotIn("TIMEOUT", result.stdout)

    def test_final_attack_follows_twenty_second_strike(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_final_trigger.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        self.assertIn("TRIGGER\t22\t0", result.stdout)
        self.assertNotIn("TIMEOUT", result.stdout)

    def test_rotating_beam_deals_five_damage(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_final_collision.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        self.assertIn("BEAM_HP\t15", result.stdout)
        self.assertNotIn("TIMEOUT", result.stdout)

    def test_sequence_and_rendering(self):
        result = subprocess.run(
            [MESEN, "--testrunner", str(ROOT / "Undertale.nes"),
             str(ROOT / "tests" / "sans_final_attack.lua")],
            cwd=ROOT, capture_output=True, text=True, timeout=120, check=True,
        )
        phases = []
        images = {}
        hitboxes = {}
        beam_duration = None
        done = False
        no_replay = False
        bones = {}
        for line in result.stdout.splitlines():
            parts = line.split()
            if not parts:
                continue
            if parts[0] == "PHASE":
                phases.append((int(parts[1]), int(parts[2])))
            elif parts[0] == "BEAM_DURATION":
                beam_duration = int(parts[1])
            elif parts[0] == "BONES":
                bones[int(parts[1])] = (int(parts[2]), int(parts[3]))
            elif parts[0] == "IMAGE":
                images[parts[1]] = Image.open(io.BytesIO(bytes.fromhex(parts[2]))).convert("RGB")
            elif parts[0] == "HITBOXES":
                hitboxes[parts[1]] = {tuple(map(int, rect.split(",")))
                                     for rect in parts[2].split(";")}
            elif parts[0] == "DONE":
                done = True
            elif parts[0] == "NO_REPLAY":
                no_replay = True
            elif parts[0] == "TIMEOUT":
                self.fail("final attack did not finish")
        self.assertEqual([phase for _, phase in phases], [1, 2, 3, 4, 5, 0])
        self.assertEqual(phases[2][0] - phases[1][0], 420)
        self.assertEqual(phases[3][0] - phases[2][0], 420)
        self.assertIn(beam_duration, (480, 481))
        self.assertTrue(done and no_replay)
        self.assertGreater(bones[1][0], 0)
        self.assertGreater(bones[2][1], 0)
        self.assertGreater(bones[3][1], 0)
        for i in range(53):
            name = str(7 + 9 * i)
            self.assertIn(name, images)
            image = images[name]
            expected = rotation.frame_image(-i % rotation.FRAMES)
            expected_hitboxes = {(x + 60, y + 126, x + 61 + w, y + 126 + h)
                                 for x, y, w, h in rotation.rectangles(expected)}
            self.assertEqual(hitboxes[name], expected_hitboxes, i)
            for y in range(64):
                for x in range(136):
                    if 118 <= x + 64 <= 135 and 153 <= y + 128 <= 169:
                        continue
                    actual = min(image.getpixel((x + 64, y + 128))) > 200
                    target = rotation.is_border(x, y) or bool(expected.getpixel((x, y)))
                    self.assertEqual(actual, target, (i, x, y))
        edge_speed = 66 * (math.pi / rotation.FRAMES) / 9
        self.assertAlmostEqual(edge_speed, 2.88, delta=0.01)
        image = images["dialogue"]
        for y in (128, 129, 190, 191):
            for x in range(8, 248):
                self.assertGreater(min(image.getpixel((x, y))), 200, (x, y))


if __name__ == "__main__":
    unittest.main()
