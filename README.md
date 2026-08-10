# Noah's Keyball44 — corne layout + dactyl trackball features

ZMK firmware for the MochuKeeb Keyball44 (nice!nano v2, nice!view displays, PMW3610
trackball). This branch (`keyball44-noah`) ports my corne layout and rebuilds the two
killer features from my old dactyl:

- **Dedicated mouse buttons** — the bottom-right key of the letter block is **left
  click**, the corner key past the trackball is **right click**. They are always
  clicks, on every layer, so a stray brush of the ball can never produce one.
- **Sticky selection** — emacs-style mark mode: `mod+space` arms it, then the nav keys
  extend the selection until you copy/cut/paste or release `mod`.

All shortcuts are macOS-flavored (Cmd-based).

## Base layer

```
ESC    Q  W  E  R  T   │   Y  U  I  O  P   BSPC
CAPS   A  S  D  F  G   │   H  J  K  L  ;   '
LSHFT  Z  X  C  V  B   │   N  M  ,  .  /   L-CLICK
                       │
SCROLL TAB ENTER MOD SYM │ BSPC SPACE   ◉ball  R-CLICK
 ⇧alt  ⇧cmd ⇧num  ⇧nav ⇧ │              (corner key)
```

There is no right Shift and no Delete — those two keys became the mouse buttons.

Left thumb row, left to right:

| Key | Tap | Hold |
| --- | --- | --- |
| bottom-left (keycap says *alt*) | toggle trackball **scroll mode** (tap again to exit) | `Option`/`Alt` |
| next (keycap says *command*) | `TAB` | `Command` |
| Enter key | `ENTER` | **NUM** layer (numpad) |
| **MOD** | — | **NAV** layer (your old `LM(1, GUI)` key) |
| inner | — | **SYM** layer |

Right side: `BSPC` + `SPACE` thumbs, **right click** on the corner key past the
trackball, `ENTER` is on the left thumb now (tap the NUM key).

## The MOD key (NAV layer)

Hold MOD and every key becomes `Cmd+<key>` (`mod+C` = copy, `mod+W` = close tab,
`mod+TAB` = app switcher...), except the nav cluster:

| Key | Plain | With shift held (tap `D` or a shift key) |
| --- | --- | --- |
| `I` / `K` | ↑ / ↓ | Page Up / Page Down |
| `J` / `L` | ← / → | Ctrl+←/→ (switch desktops) |
| `U` / `O` | word left / word right (⌥←/⌥→) | — |
| `H` | end of line (⌘→) | start of line (⌘←) |
| `E` | delete word back (⌥⌫) | — |
| `M` / `,` | back / forward (⌘[ / ⌘]) | — |
| `D` | acts as Shift inside NAV | — |
| top-right `BSPC` | delete line (⌘⌫) | — |

The trackball **scrolls** while MOD is held (like holding MOVE on the dactyl).

## Sticky selection

1. Hold **MOD**, tap **SPACE** → selection mode armed.
2. Still holding MOD, use the nav keys — they now select:
   `I/K/J/L` = shift+arrows, `U/O` = select word left/right, `H` = select to
   end/start of line (shifted: page-select with `I/K`).
3. Exit by any of:
   - `mod+C` (copy) or `mod+X` (cut) — performs ⌘C/⌘X, taps `ESC`, exits
   - `mod+V` (paste) — ⌘V, exits
   - `mod+SPACE` again
   - releasing MOD

## Trackball

| Thing | How |
| --- | --- |
| Point | just move the ball |
| Left click | bottom-right key of the letter block (where right Shift would be) |
| Right click | corner key past the trackball |
| Scroll mode (locked) | tap the bottom-left key; tap again to exit |
| Scroll (momentary) | hold MOD |
| Pointer speed (coarse) | `CONFIG_PMW3610_CPI` (400), same file — steps of 200 only |
| Pointer speed (fine) | `&zip_xy_scaler 7 8` on `trackball_listener` in `keyball44_right.overlay` — effective speed is `CPI * mul / div`, currently 350 |
| Reach on fast flicks | `CONFIG_PMW3610_ACCELERATION_SENSITIVITY` (1, max **10**); `CONFIG_PMW3610_ACCELERATION_ALGORITHM=0` disables it |
| Scroll speed | `CONFIG_PMW3610_SCROLL_TICK` (11; higher = slower) |

Tuning notes, because two of these are traps:

- **Leave `CONFIG_PMW3610_CPI_DIVIDOR` at 1.** It is not a sensor setting — it is an
  integer divide applied to every motion report. Any value above 1 truncates small
  deltas to zero, so slow ball movement is discarded entirely and the pointer only
  responds once you move fast enough to clear the divisor. Set speed with CPI, which
  the sensor applies in hardware without dropping counts.
- **`SCROLL_TICK` is tied to `CPI`.** Scroll mode ignores the divisor and counts raw
  sensor ticks, so halving CPI halves scroll speed unless `SCROLL_TICK` comes down
  with it. The `zip_xy_scaler` does *not* affect scroll — it only matches
  `REL_X`/`REL_Y` — so trimming speed there leaves scrolling alone.
- **Prefer the scaler over CPI for small adjustments.** CPI's 200-step granularity is
  a 50% jump down at this end of the range. The scaler tracks remainders across
  reports, so it slows the pointer without reintroducing the truncation problem.
- **Two separate dials, don't confuse them.** The scaler sets how fast slow movement
  is; acceleration (`output = x + x²/divider`, `divider = 22 - 2*sensitivity`) sets
  how much extra fast movement gets. Reports of 1 count or less skip acceleration
  entirely, so raising sensitivity never coarsens precise movement. "Can't cross the
  screen" → raise sensitivity. "Too twitchy when nudging" → lower the scaler.
- **Acceleration gets jumpy quickly.** The quadratic term means the boost grows with
  the square of speed, so the gap between a normal move and a fast one widens fast.
  Sensitivity above ~2 is noticeably aggressive on a ball this small. If the pointer
  feels unpredictable rather than merely fast, that is acceleration, not speed —
  turn it off with `ACCELERATION_ALGORITHM=0` and raise the scaler instead.
- **Never set `ACCELERATION_SENSITIVITY` above 10.** Kconfig accepts up to 100, but
  the driver computes `divider = 22 - 2*sensitivity`, so 11 divides by zero.
- **Pointer lags over Bluetooth?** Report rate, not speed. The polling options are
  misnamed: `250` and `125_SW` both run the sensor at 250Hz, and `125_SW` merely
  discards every other report and folds it into the next (hence its extra latency).
  Only plain `CONFIG_PMW3610_POLLING_RATE_125` slows the sensor itself. The ball is on
  the central, so its reports go straight to the host — but at the negotiated
  7.5–11.25ms connection interval that link carries only ~90–130 events/sec and cannot
  drain 250 reports/sec, so the backlog shows up as lag that grows while you keep
  moving. 125 is the setting for wireless use; 250 is fine with the right half on USB.
- Still laggy at 125? `CONFIG_BT_PERIPHERAL_PREF_LATENCY` is 16, meaning the radio
  may skip up to 16 connection events to save power. Lowering it trades battery for
  responsiveness.
- **Small movements missed, but only sometimes?** The sensor steps down through
  RUN → REST1 → REST2 → REST3 as the ball sits idle, sampling less often at each
  step, and a movement slow enough to finish between two samples is never seen.
  How long the ball rested decides which state it is in, hence the intermittency.
  The trap is that the driver guards the REST2/REST3 knobs with `#if <value> >= 10`,
  so leaving them blank means the hardware defaults apply — about 100ms and 500ms
  between samples. All the rest timings are set explicitly in
  `keyball44_right.conf`; note that an out-of-range value is rejected at init and
  the register silently keeps its default, so respect the bounds documented there.

  Sampling *is* the wake mechanism — there is no separate low-power motion
  detector, so each state's sample interval is also its worst-case wake latency.
  "Deeply idle but instantly awake" is therefore not available; the settings are
  weighted for battery, with a short-lived fast state (20ms for 9.6s) and deep
  states at 50ms and 150ms. To trade battery for responsiveness, lengthen
  `REST1_DOWNSHIFT_TIME_MS` so the fast state lasts longer, or shorten the deep
  sample times. `CONFIG_PMW3610_FORCE_AWAKE=y` is the extreme: RUN mode always.
- Every nudge losing its first count is a different problem — that is the
  `zip_xy_scaler`, which banks a fraction below 1 as a remainder and only emits
  once it accumulates. It never discards anything, but a single tiny nudge can
  move nothing until the next one. Raising the scaler toward `1 1` removes it.

The auto-mouse layer is off (`automouse-layer = <0>` in `keyball44_right.overlay`),
which compiles the mechanism out of the driver — moving the ball never changes a
layer. `CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS` and `CONFIG_PMW3610_MOVEMENT_THRESHOLD`
are therefore inert; they only matter if the auto-mouse layer is turned back on. The
MOUSE layer node stays in the keymap regardless, because SCROLL and SNIPE are indexed
off its position.

A SNIPE (precision) layer exists for the driver but has no key bound — bind `&mo SNIPE`
somewhere in `config/keyball44.keymap` if you want it.

## Other layers

- **SYM** (hold inner-left thumb): `! @ # $ %` / `~ \` { } [` on the left,
  `^ & * + =` / `] ( ) ' "` on the right, `- _ |` on the bottom, `_`/`-` on the
  right thumbs. Same as the corne's symbol layer.
- **NUM** (hold the Enter key): right-hand numpad (`789 / 456 / 123`, `0` on SPACE),
  ⌥⇧S/D/F on the left home row, ⌘SPACE (Spotlight) on the BSPC thumb, and the
  terminal control keys macOS has no room for because ⌘ owns those chords:

  | Key | Sends | For |
  | --- | --- | --- |
  | `C` | `Ctrl+C` | interrupt |
  | `R` | `Ctrl+R` | reverse history search |

  Nothing destructive goes on NUM's left half. Its thumb key is adjacent to MOD, so
  a thumb catching both puts NUM (layer 4) above NAV (layer 1) and fires left-half
  NUM bindings during ordinary `mod+C` / `mod+V` / `mod+D` use.
- **SYS** (hold NUM + SYM together — two thumb keys, so it can't be hit by accident):

  | Key | Action |
  | --- | --- |
  | `A` `S` `D` `F` `G` | select Bluetooth profile 0–4 |
  | `Q` `W` `E` | output USB / BLE / toggle |
  | `X` / `C` | clear this profile's pairing / clear **all** profiles |
  | `Z` / outer Shift | `sys_reset` / `bootloader` — left keys act on the left half, right keys on the right |
  | right half | F1–F12 |

  **If the keyboard ever goes silent but the displays still work**, you are almost
  certainly on an unpaired Bluetooth profile: hold NUM+SYM and press `A` for profile
  0. The selection is stored in flash, so power-cycling will *not* undo it.

## Day-1 install

### 0. Build the firmware (locally)

One-time setup (installs cmake/ninja/dtc/uv via Homebrew, pulls ~2GB of
ZMK/Zephyr sources into this repo — gitignored — and the Zephyr ARM toolchain
into `~/zephyr-sdk-0.16.8`):

```sh
./build.sh setup
```

Then every build is just:

```sh
./build.sh
```

Output lands in `./firmware/`:

- `keyball44_right.uf2` — **right half: the central**. Holds the keymap, talks to
  the host, runs ZMK Studio, drives the trackball. Any keymap edit goes here.
- `keyball44_left.uf2` — left half (peripheral; only reports key positions)
- `settings_reset.uf2` — pairing reset

Incremental rebuilds after keymap edits take seconds. `./build.sh clean` wipes
the build output if things get weird. (Pushing to a GitHub fork also still works —
the stock ZMK Actions workflow in `.github/workflows/` builds the same targets.)

### 1. (First time / pairing problems) flash `settings_reset`

Flash it to **both** halves, power-cycle both, wait ~10s. This wipes stored pairing
so the halves can find each other cleanly.

### 2. Flash each half

For each half, **plug it in over USB** and **double-tap the reset button** — it mounts
as a USB drive called `NICENANO`. Drag the matching `.uf2` onto it; it flashes and
reboots itself:

1. Left half ← `keyball44_left ... .uf2`
2. Right half ← `keyball44_right ... .uf2`

The right half is the central, so **keymap changes only need the right half flashed**.
The left half only needs it when its own shield config changes.

`./flash.sh all` does the copying instead: it walks the whole first-time sequence
(settings_reset on both halves, power-cycle, then the real firmware on each),
waiting for the drive to mount at each step so the only thing to do by hand is the
double-tap. `./flash.sh left|right|reset` flashes a single target.

**Finding the reset button**: it sits on the PCB *directly underneath the display*,
so the protective cover over the nice!view has to come off to reach it. This is a
one-time chore — this keymap puts `&bootloader` on the SYS layer, so afterwards hold
the two thumb keys (NUM + SYM) and press the outer Shift key (left Shift reboots the
left half, right Shift the right).

### 3. Pair

Turn both halves on. They pair to each other automatically (**right is central**).
Then on the Mac: System Settings → Bluetooth → connect to **Keyball44**. The right
half is the one that talks to the computer — plug USB into it if you prefer wired.

Five Bluetooth profiles are available (0–4): hold NUM+SYM together (the SYS layer)
and press `A`–`G` to switch, `X` to clear the current profile's pairing.

### 4. If something's weird

- Halves not talking to each other → step 1 (settings_reset both), then reflash.
- Trackball not moving → it's on the right half; make sure the right half got the
  right firmware and is powered.
- Live keymap tweaks: ZMK Studio is enabled — plug in the **right** half over USB and
  use [ZMK Studio](https://zmk.dev/docs/features/studio). Note Studio edits are
  runtime-only overrides; this repo's keymap stays the source of truth.

## Upstream

Forked from [mochukeeb/zmk-config-keyball44](https://github.com/mochukeeb/zmk-config-keyball44)
(`niceview` branch — for nice!view displays; there's an `oled` branch upstream for OLED
boards, don't mix them up).
