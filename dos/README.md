# Soul Dodge for MASM/TASM

This is a separate 16-bit DOS version of Soul Dodge. It keeps the NES ROM
project intact and builds as a DOS `.EXE` using either MASM or TASM.

## Run it on Windows

1. Open the game's `dos` folder in File Explorer.
2. Double-click [`RUN_GAME.bat`](./RUN_GAME.bat).
3. Wait for DOSBox to open; the launcher builds and starts the game for you.
4. Play with **W/A/S/D** or the **arrow keys**; press **Space** to attack.
   Close the DOSBox window to exit.

You do not need to open Command Prompt or type DOSBox commands. The launcher
uses the TASM bundle in `%TEMP%\masm-tasm\bundles\TASM` and looks for DOSBox
0.74-3 in either standard Program Files folder. If it reports that either
program is missing, install/restore that program and double-click the batch
file again. The source is copied to a temporary workspace and built each time.

The program uses DOS BIOS video, keyboard, and timer services. Windows 64-bit
cannot run the resulting 16-bit DOS executable directly, which is why the
launcher builds and runs it inside DOSBox.

## Controls and objective

- The battle screen uses a dark background, white frames, a red soul, and an
  LV/HP display with a health bar.
- Survive an obstacle round before each of the five original boss fights. The
  first round lasts 30 seconds; each boss victory adds 30 seconds to the next
  round. After each of the first four bosses, HP is fully restored and another
  obstacle round begins. The final boss victory restores HP and wins the game.
- Move with **W/A/S/D** or the **arrow keys** and dodge the falling `*` bullets.
- Catch the falling red heart (`♥`) to recover up to 3 HP, up to the 20-HP
  maximum. Healing hearts appear periodically during survival and boss fights.
- During boss fights, press **Space** to fire a `^` projectile at the moving
  boss. Line up beneath it; a hit flashes `!! HIT !!`. Each boss needs multiple
  hits. A boss victory fully restores HP; the first four victories lead into
  another obstacle round.
- The boss rush gets harder in order:

  | Boss | Difficulty | Hits to defeat | Safe gap |
  |---|---|---:|---:|
  | Wisp of Cinders | Easy | 8 | 8 cells |
  | Bramble Jack | Fair | 10 | 7 cells |
  | Mirror Moth | Normal | 12 | 6 cells |
  | Clockwork Crow | Hard | 14 | 5 cells |
  | The Obsidian Crown | Final | 16 | 4 cells |

  Later bosses also launch attacks more frequently.
- The obstacle rounds start at a slower pace. Each boss victory makes the next
  round's bullets fall and spawn faster.
- After defeating the third boss, a small spaceship appears in obstacle rounds
  every 10 seconds. It moves in random directions, shoots at the player, and
  leaves after about 5 seconds.
- Keep at least 1 HP through all five fights to win. Press **Q** to quit, or
  **R** after winning or losing to restart.
