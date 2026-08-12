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
  Any new layer goes on the END so those three never have to move — a layer's
  index is its position among the `keymap` node's children, so appending the
  `#define` alone is not enough; the layer node must be last too.
- `scroll-layers = <7 1 2>` is intentional: the ball scrolls while the mod key
  is held (dactyl parity), not just in toggled scroll mode.
- `automouse-layer = <0>` disables the auto-mouse layer at compile time (the
  driver wraps the whole mechanism in `#if AUTOMOUSE_LAYER > 0`). Clicks are
  dedicated keys on the base layer instead. `CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS`
  and `CONFIG_PMW3610_MOVEMENT_THRESHOLD` are dead while this is 0. The MOUSE
  layer node must stay in the keymap anyway — SCROLL (7) and SNIPE (8) are
  indexed off its position.
- `CONFIG_PMW3610_CPI_DIVIDOR` must stay 1. It is an integer divide on each
  motion report (`raw_x = TOINT16(...) / dividor` in the driver), not a sensor
  register, so >1 floors small deltas to zero and kills slow tracking. The
  shipped-config value of 4 was the cause of the "too sensitive but sometimes
  dead" feel. Change pointer speed with `CONFIG_PMW3610_CPI` instead. If CPI
  moves, move `CONFIG_PMW3610_SCROLL_TICK` with it — scroll mode ignores the
  dividor and counts raw ticks, so the two are coupled.
- Trackball report rate is a latency budget, not a smoothness dial. The ball sits
  on the central, so reports reach the host in one hop, but the negotiated
  connection interval is 7.5-11.25ms — roughly 90-130 events/sec — so 250Hz backs
  up and the pointer falls progressively behind while moving.
  `CONFIG_PMW3610_POLLING_RATE_125` fixed it.
  The three options are misnamed: `250` and `125_SW` both write register `0x0D`
  (250Hz) and `125_SW` merely discards every other report in software, which is
  where its reputation for lag comes from; only plain `125` (register `0x00`)
  slows the sensor. 250 is fine with the left half on USB.
- Pointer speed has two independent dials and they answer different complaints.
  `&zip_xy_scaler <mul> <div>` on `trackball_listener` sets the slow-movement
  floor (it tracks remainders, so unlike `CPI_DIVIDOR` it loses nothing);
  `CONFIG_PMW3610_ACCELERATION_*` adds reach on fast flicks. Which acceleration
  algorithm is selected changes what sensitivity means, so never carry a value
  between them: `ALGORITHM=1` is quadratic on per-report size, unbounded, jumpy
  above ~2 and a divide-by-zero at 11; `ALGORITHM=2` (in use) is a sigmoid on
  measured speed whose gain is capped at sensitivity itself, which makes the
  number a maximum multiplier and safe to raise. 2 is also the only one worth
  stacking on top of the macOS curve, which is the arrangement here — a low macOS
  tracking slider for precision, firmware acceleration for reach.
- Check thumb placement FIRST. The sensor is side-mounted, so it images the ball
  from one side: a thumb resting on top of the ball presses it away from that
  lens, past the focal range, and tracking stops until the pressure eases.
  Driving the ball from the side keeps it seated. This was the real cause of a
  long run of "it misses movement" reports, after CPI, scaler ratios, polling
  rate, rest timings, BLE latency and macOS acceleration had all been changed
  in pursuit of it. It presents as random dropouts at any speed, because it
  tracks pressure rather than speed.
- Trackball "misses movement" is mechanical until proven otherwise. A long tuning
  session chased this through CPI, scaler ratios, polling rate, rest timings, BLE
  latency and macOS acceleration; the cause was the ball sticking in its bearings
  (made worse by cleaning it with a disinfecting wipe, which leaves a film). The
  USB logging build settles it in minutes — `./build.sh debug`, `./flash.sh debug`,
  `./capture-log.sh 15 > trackball.log`. The signature of a mechanical fault is
  that every gap in motion reports is *bracketed by deceleration and
  acceleration*: the ball slows to a near-stop, reports nothing, then speeds up.
  A genuine sensor or link dropout interrupts motion abruptly, with large reports
  either side. Zero SPI errors plus 97% of reports inside 10ms means the whole
  electrical and firmware path is fine.
- Measure the pointer with `tools/cursorgaps.swift`, never by frame-differencing
  a screen recording. QuickTime drops frames under load — two captures of the
  same fault came out at 52fps and 37.6fps against a nominal 60 — and a dropped
  frame is indistinguishable from a frozen cursor. That artefact is what made a
  BLE latency change look like it helped. Healthy reference, measured with a
  freely spinning ball at the stock slave latency of 16: ~115 updates/sec,
  median gap 8.2ms, p90 8.9ms, p99 15.5ms, 99% inside 16ms.
- `kscan0` in `keyball44.dtsi` must keep `wakeup-source;`. Both halves deep-sleep
  after 15 minutes (`CONFIG_ZMK_SLEEP` in `config/keyball44.conf`, which applies to
  both builds — the shield's per-half confs are for hardware that differs). The
  vendor shield shipped without the property, which made the sleeping half
  unrecoverable: deep sleep is nRF52 System OFF, exited only by a
  GPIO DETECT event or a reset, and `zmk_pm_suspend_devices` (`zmk/app/src/pm.c`)
  arms the matrix only when the node is wakeup-capable — otherwise it suspends it,
  and `kscan_matrix_pm_action` disconnects every row and column pin on the way
  down. Symptom: display dark, no input, no BLE, and only the power switch brings
  it back. Compare against stock ZMK shields, which all carry the property.
- The mod key is the `nav_mod` macro, not a plain `&mo`: on release it taps
  `&tog_off SELECT` so sticky selection always dies with the mod key. Don't
  "simplify" it to `&mo NAV`.
- NAV's TAB key is the `app_switch` macro, and the point of it is that it holds Cmd
  for the duration of the key press rather than for the duration of one Tab. Don't
  "simplify" it to `&kp LG(TAB)`: that closes the switcher inside the keypress, which
  is the whole reason the macro exists. It also has to keep its press and release
  balanced — ZMK counts explicit modifier registrations, so pressing Cmd more often
  than releasing it leaves Cmd stuck down.
- SELECT must stay a higher layer index than NAV (it overlays it), and mostly
  `&trans` so unlisted keys fall through to NAV's Cmd bindings.
- Left thumb cluster, outer to inner: scroll/Alt, TAB/NUM, ENTER/Shift, MOD, SYM.
  Shift is a thumb hold rather than the outer pinky key because palming that key
  is awkward on a board this narrow; Command took the pinky key in exchange, and
  NUM moved outward one key to free the Enter thumb for Shift. The keycap legends
  (*alt*, *command*) date from the previous arrangement and no longer match.
  Consequences worth knowing before rearranging again: the global `&mt` block is
  now used by nothing but the Shift key, so its flavor is tuned for Shift
  (`balanced` — see the comment on it) rather than for a tap-first key; and SYS
  (SYM+NUM) spans the cluster's two ends instead of two neighbours.
- Enter being the Shift key's tap means shift+enter needs a second key. It is on
  both of the neighbouring press orders: the NUM key is `&num_tab`, whose tap
  morphs TAB -> shift+enter while shift is held, and NUM's own layer puts
  `&kp LS(ENTER)` on the Enter/Shift thumb. Note `num_tab`'s tap side is a
  zero-parameter mod-morph, so the keymap passes a dummy `0` as its second
  parameter (`&num_tab NUM 0`) — hold-tap always takes two.
- Ctrl lives only on the corner key's hold (`rclk_ctrl`, tap = right click). The
  corne had it twice — a seventh column this board lacks, and the hold of its
  `LCTL_T(ENTER)` right thumb — and Enter moved to the left thumb here, so both
  were lost in the port. Ctrl+C and Ctrl+R also sit on NUM, from before the key
  existed; they are redundant now but harmless.
- Deliberate deviations from the Vial dump, so they are not "fixed" by mistake:
  `mod`+space is sticky selection where the corne had Opt+Space; Caps Lock gave
  its key to Tab; Delete gave its key to right click; the top-right Backspace,
  a duplicate of the right thumb's, gave its key to the scroll toggle so scroll
  mode is reachable with the right hand alone (`mod` still makes it Cmd+Backspace,
  as does `mod`+the thumb Backspace); `mod`+`'` is Cmd+Enter (VSCode's auto-import)
  where the dump's blanket Cmd made it Cmd+'. Everything else in NAV,
  SYM and NUM matches the dump binding for binding — verified by decoding
  `~/source/vial_config_final_4.vil` and diffing against the compiled keymap.
- All shortcuts are macOS-flavored (Cmd/Opt). The corne/dactyl configs were Mac.
- ZMK is pinned to v0.3 in `config/west.yml`; `toggle-mode = "on"/"off"` on
  `zmk,behavior-toggle-layer` requires ≥ v0.3.
- When porting a Vial key-override, `negative_mod_mask` is as important as
  `trigger_mods`: it lists mods that *suppress* the override, so the key falls
  through to itself with whatever `LM()` was applying still attached. Several
  NAV keys rely on this — `mod`+shift+`O`/`U` are Cmd+Shift+O/U (app shortcuts),
  not shifted word-jumps. Missing it silently turns them into text selection,
  which looks like a sticky-selection bug and is not one. One override remains
  unported by choice: `KC_F` + shift on NAV mapped to `KC_NO`, disabling
  `mod`+shift+`F`; here it still sends Cmd+Shift+F.
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
- `west update` passes `--fetch-opt=--no-tags`. Without it, re-running setup on a
  populated workspace fails with `can't import from project zephyr`: git's tag
  auto-following lists all 118 already-present zephyr tags in `FETCH_HEAD` ahead
  of the fetched branch, west resolves `FETCH_HEAD` to its first line, and zephyr
  lands on the v1.0.0 tag (2016, pre-west, no `west.yml`). To recover a workspace
  already in that state: `git -C zephyr update-ref refs/heads/manifest-rev <sha>`
  for the real `v3.5.0+zmk-fixes` sha (`git -C zephyr ls-remote zmkfirmware
  refs/heads/v3.5.0+zmk-fixes`), `git -C zephyr checkout --force manifest-rev`,
  then re-run setup.

Artifacts land in `./firmware/` (left, right, settings_reset). Flashed and
running on hardware as of 2026-08-10.

**The RIGHT half is the central** (`ZMK_SPLIT_BLE_ROLE_CENTRAL` is defaulted on
for `SHIELD_KEYBALL44_RIGHT` in `Kconfig.defconfig`). It holds the keymap, is the
endpoint the host pairs with, runs ZMK Studio, and carries the trackball. The
left half is the peripheral and only reports key positions.

So **keymap edits are a right-half flash**, as are all of `keyball44_right.conf`
and `keyball44_right.overlay`. The left half only needs reflashing when its own
shield config changes — rarely. Reading this backwards wastes a lot of time,
because a keymap change flashed to the left half silently does nothing.

## Flashing

`./flash.sh all` for a first-time flash, or `./flash.sh left|right|reset` for
one target. It waits for the bootloader drive to mount, copies, and treats the
drive disappearing as the success signal.

- The physical reset button is on the PCB **directly underneath the display**;
  the nice!view cover has to come off to reach it. Only needed when a half is
  running firmware without `&bootloader`. This keymap has it on SYS (hold
  NUM+SYM, press the outer key of the bottom letter row — locality-aware, each
  half reboots itself),
  so day-to-day flashing needs no disassembly.
- `cp -X` matters. macOS writes extended attributes after the file data, and the
  board reboots the moment the last UF2 block lands, so a plain `cp` always
  fails that trailing pass with `Device not configured` even on a good flash.
- Never `sudo ./flash.sh`. When the board reboots it yanks the USB device out
  from under the filesystem and macOS can leave `/Volumes/NICENANO` behind as an
  ordinary directory on the boot disk. Running as root writes root-owned files
  into that leftover, which stops macOS from auto-cleaning it, and every
  subsequent flash then silently targets the SSD. `flash.sh` now requires
  `INFO_UF2.TXT` (written by the bootloader) before it will write anywhere, and
  warns about leftovers; the fix for one is `sudo rm -rf /Volumes/NICENANO`.

## Git / remote situation

`origin` is `ChewingGlass/zmk-config-keyball44`, Noah's fork, and is writable.
The upstream it was forked from is the `mochukeeb` remote, which is read-only —
never push there. Work happens on the `keyball44-noah` branch and is published to
`master` on the fork, so a push is `git push origin keyball44-noah:master`.
Upstream has no main branch; `niceview` (our base) and `oled` are
display-specific — don't mix firmware.

## Day-1 checklist

Worked through on hardware 2026-08-10; kept as the regression list. Re-verify
these after any keymap or trackball change:

1. Halves pair; typing works on the base layer; Enter = tap of the Shift thumb
   key, capitals = hold it (if Enter misfires while rolling keys, or capitals
   need waiting out, tune the global `&mt` block: tapping-term 240ms /
   balanced / quick-tap 150).
2. Trackball points; left click = bottom-right key of the letter block, right
   click = corner key past the ball. Both are plain `&mkp` on the base layer,
   not an auto-mouse layer. Pointer speed via `CONFIG_PMW3610_CPI` plus the
   `zip_xy_scaler` on the listener; scroll direction via the INVERT_SCROLL opts.
3. Scroll: the top-right key is `&tog SCROLL`, reachable with the right hand
   alone; it works to toggle back off because SCROLL is all `&trans` and falls
   through to it. Bottom-left thumb: tap toggles scroll lock, hold is Option/Alt (`scroll_alt`
   hold-tap). Next thumb key: tap TAB, hold NUM, and tap-with-shift-held for
   shift+enter (hold NUM + tap Enter does the same). Ball scrolls while mod held.
4. Mod key: mod+C copies, mod+J/K/L/I arrows, mod+U/O word-jump, mod+H
   end-of-line (shift+ for start), shift+mod+I/K page up/down, mod+D acts as
   shift. mod+TAB held keeps the app switcher open and mod+J/L move the
   selection in it; a quick tap of mod+TAB is a plain Cmd+Tab.
5. Sticky selection: mod+space, then mod+jkliuo extends selection; mod+C/X/V
   exits (copy/cut also tap ESC — dactyl parity; drop ESC from the sel_copy/
   sel_cut macros if it misbehaves in some app); releasing mod exits.
6. SYS layer (hold NUM+SYM): A–G select BT profiles 0–4, Q/W/E pick output,
   X/C clear this profile / all profiles; bootloader and reset keys are
   locality-aware (left-side key acts on the left half, right-side key on the
   right). NUM and SYM are now the second and fifth thumb keys, so SYS takes
   thumb-plus-index rather than one thumb. BT profile select briefly lived on
   NUM's left half and caused a "dead keyboard": NUM (4) outranks NAV (1), so a
   press catching both keys made `mod+D` fire `&bt BT_SEL 2` —
   an unpaired profile. Symptoms were displays fine, base layer, BLE showing
   connected, zero input; and `&bt` selection persists across a power cycle, so
   only `BT_SEL 0` recovers it. Keep destructive bindings off single-thumb-key
   layers. Space was also tried as a layer key and rejected — too hot a key for
   a hold-tap.
