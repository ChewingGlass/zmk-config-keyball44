# Project context for agents

ZMK config for Noah's Keyball44 (nice!nano v2, nice!view, PMW3610 trackball).
The working branch is `keyball44-noah`. README.md has the user-facing layout
docs and flash instructions — read it first. This file is the handoff context
that isn't obvious from the code.

## Where this layout came from

- Base layout: Noah's old corne, decoded from the Vial dump at
  `~/source/vial_config_final_4.vil`. Its "mod" thumb key was QMK `LM(1, LGUI)`
  (hold = Cmd + nav layer) with Vial key-overrides stripping Cmd on arrows.
  ZMK has no LM, so `nav_layer` binds every key explicitly to `LG(<key>)` and
  the nav cluster (I/J/K/L arrows, U/O word-jump, H line start/end) to plain
  motions, with mod-morphs reproducing the shift-variant overrides.
- Sticky selection + trackball click behavior: ported from the old dactyl at
  `~/source/qmk_firmware/keyboards/handwired/dactyl_manuform/4x5/keymaps/default/keymap.c`
  (see `KC_SEL_A`, `KC_SEL_*`, `mouse_or_key()`, `KC_SCROLL` there if parity
  questions come up).

## Invariants / gotchas

- Layer indices in `config/keyball44.keymap` (`#define MOUSE 6`, `SCROLL 7`,
  `SNIPE 8`, `NAV 1`, `SELECT 2`) MUST match the pmw3610 driver properties in
  `config/boards/shields/keyball_nano/keyball44_right.overlay`
  (`automouse-layer`, `scroll-layers`, `snipe-layers`). Renumber both together.
- `scroll-layers = <7 1 2>` is intentional: the ball scrolls while the mod key
  is held (dactyl parity), not just in toggled scroll mode.
- The mod key is the `nav_mod` macro, not a plain `&mo`: on release it taps
  `&tog_off SELECT` so sticky selection always dies with the mod key. Don't
  "simplify" it to `&mo NAV`.
- SELECT must stay a higher layer index than NAV (it overlays it), and mostly
  `&trans` so unlisted keys fall through to NAV's Cmd bindings.
- All shortcuts are macOS-flavored (Cmd/Opt). The corne/dactyl configs were Mac.
- ZMK is pinned to v0.3 in `config/west.yml`; `toggle-mode = "on"/"off"` on
  `zmk,behavior-toggle-layer` requires ≥ v0.3.
- ZMK keycode spelling: QMK's `LSA(x)` is `LS(LA(x))` — already bit us once.
- ZMK Studio is enabled (right half over USB). Studio edits are runtime
  overrides; if a flashed keymap change doesn't seem to apply, a Studio
  override may be shadowing it.

## Building

`./build.sh` (after one-time `./build.sh setup`). Local west build — no GitHub
needed. Notes baked into the script, learned the hard way:

- Homebrew's `python@3.11` bottle is broken on this Mac (libexpat symbol
  mismatch), so setup uses `uv venv --python 3.11`.
- `setuptools<81` is pinned because setuptools 83 removed `pkg_resources`,
  which nanopb's protoc wrapper (ZMK Studio protobufs) still imports.
- The venv must be first on PATH during builds (nanopb scripts use
  `#!/usr/bin/env python3`).
- Zephyr SDK 0.16.8 lives at `~/zephyr-sdk-0.16.8` (arm-zephyr-eabi only).

Artifacts land in `./firmware/` (left, right, settings_reset). Verified
compiling on 2026-07-23; **not yet tested on hardware** — the keyboard hadn't
arrived.

## Git / remote situation

`origin` is `mochukeeb/zmk-config-keyball44` and Noah has READ-ONLY access —
you cannot push. If a remote is ever wanted, Noah must fork first (a previous
attempt to `gh repo fork` was permission-blocked). Upstream has no main branch;
`niceview` (our base) and `oled` are display-specific — don't mix firmware.

## Day-1 checklist (when the keyboard arrives)

Flash per README, then verify with Noah, tuning as needed:

1. Halves pair; typing works on the base layer; Enter = tap of the NUM thumb
   key (if Enter feels laggy or misfires while rolling keys, tune the global
   `&lt` block: tapping-term 240ms / balanced / quick-tap 150).
2. Trackball points; U/J left-click, I/K right-click within 400ms of movement
   (`CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS` in `keyball44_right.conf`); pointer
   speed via `CONFIG_PMW3610_CPI`; scroll direction via the INVERT_SCROLL opts.
3. Scroll toggle (bottom-left key) locks/unlocks scroll; ball scrolls while
   mod held.
4. Mod key: mod+C copies, mod+J/K/L/I arrows, mod+U/O word-jump, mod+H
   end-of-line (shift+ for start), shift+mod+I/K page up/down, mod+D acts as
   shift.
5. Sticky selection: mod+space, then mod+jkliuo extends selection; mod+C/X/V
   exits (copy/cut also tap ESC — dactyl parity; drop ESC from the sel_copy/
   sel_cut macros if it misbehaves in some app); releasing mod exits.
6. SYS layer (hold NUM+SYM): BT profile select/clear for pairing to more
   devices; bootloader keys are locality-aware (left-side key reboots left
   half, right-side key the right half).
