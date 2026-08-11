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
ESC   Q  W  E  R  T   │   Y  U  I  O  P   SCRL
TAB   A  S  D  F  G   │   H  J  K  L  ;   '
CMD   Z  X  C  V  B   │   N  M  ,  .  /   L-CLICK
                      │
SCROLL TAB ENTER MOD SYM │ BSPC SPACE   ◉ball  R-CLICK
 ⇧alt  ⇧num ⇧shft ⇧nav ⇧ │              (⇧ctrl)
```

**Shift is a thumb hold, not a pinky key.** Palming the outer bottom-left key is
awkward on a board this small, so Shift sits on the hold of the `ENTER` thumb key
and `Command` takes the pinky key Shift used to have. `NUM` moved up one thumb
key in the swap, onto the key whose keycap says *command* — the three thumb-cluster
legends (*alt*, *command*, and the blank Enter key) no longer describe what the
keys do.

There is no right Shift and no Delete — those two keys became the mouse buttons —
and no Caps Lock, whose key is now `TAB`. `TAB` is also still the tap of the
second left thumb key, so it is reachable either way.

The top-right key is **scroll mode**, not a second Backspace. Backspace is the right
thumb, which is the one that actually gets used; the corner key duplicated it and now
earns its keep as the one scroll toggle the right hand can reach alone. `mod` still
makes it ⌘⌫ (delete line).

Left thumb row, left to right:

| Key | Tap | Hold |
| --- | --- | --- |
| bottom-left (keycap says *alt*) | toggle trackball **scroll mode** (tap again to exit) | `Option`/`Alt` |
| next (keycap says *command*) | `TAB`, or **shift+enter** while Shift is held | **NUM** layer (numpad) |
| Enter key | `ENTER` | **Shift** |
| **MOD** | — | **NAV** layer (your old `LM(1, GUI)` key) |
| inner | — | **SYM** layer |

The Shift key is `&mt LSHFT ENTER` on the `balanced` flavor, so a capital letter
resolves the moment the letter is released rather than after the 240ms tapping
term — `tap-preferred`, which the other hold-taps use, would make every shifted
character wait out the timer.

**shift+enter** can't come from that key alone, since Enter is its tap. It is the
two Enter-side thumb keys together, in either order: hold Shift and tap the NUM key
(whose tap morphs from `TAB` to shift+enter while Shift is down), or hold NUM and
tap the Enter key. The cost is shift+`TAB` from that thumb, which is still on the
`TAB` key in the letter block.

Right side: `BSPC` + `SPACE` thumbs, `ENTER` is on the left thumb now (tap the NUM
key). The corner key past the trackball is **tap = right click, hold = Ctrl** —
the corne carried Ctrl on a seventh column this board doesn't have and as the
hold of its Enter thumb, so this is its only home.

## The MOD key (NAV layer)

Hold MOD and every key becomes `Cmd+<key>` (`mod+C` = copy, `mod+W` = close tab,
`mod+TAB` = app switcher...), except the nav cluster:

| Key | Plain | With shift held (`D`, or hold the `ENTER` thumb key) |
| --- | --- | --- |
| `I` / `K` | ↑ / ↓ | Page Up / Page Down |
| `J` / `L` | ← / → | Ctrl+←/→ (switch desktops) |
| `U` / `O` | word left / word right (⌥←/⌥→) | ⌘⇧U / ⌘⇧O (app shortcuts — ⌘⇧O is VSCode's Go to Symbol) |
| `H` | end of line (⌘→) | start of line (⌘←) |
| `E` | delete word back (⌥⌫) | — |
| `M` / `,` | back / forward (⌘[ / ⌘]) | — |
| `TAB` | app switcher: tap = last app, **hold** = switcher stays open, pick with `J`/`L`, release to commit | — |
| `D` | acts as Shift inside NAV | — |
| top-right key | delete line (⌘⌫) | — |

The trackball **scrolls** while MOD is held (like holding MOVE on the dactyl).

`mod`+`TAB` is a real app switcher rather than a one-shot ⌘⇥, because the switcher
only stays up while ⌘ is physically held and a `&kp LG(TAB)` releases it inside the
keypress. That key holds ⌘ for as long as you hold it, so the switcher behaves the
way it does on any Mac keyboard: hold, choose, release. `mod`+the NUM thumb key is
still the plain one-shot ⌘⇥ for bouncing between two apps, and it also advances the
switcher while `mod`+`TAB` is being held.

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
| Right click | **tap** the corner key past the trackball (**hold** it for Ctrl) |
| Scroll mode (locked) | tap the **top-right** key (right hand alone) or the bottom-left thumb key; tap either again to exit |
| Scroll (momentary) | hold MOD |
| Pointer speed | `CONFIG_PMW3610_CPI` (1600) **plus** macOS → Mouse → Tracking speed; the slider is the fine adjustment |
| Fine speed trim | `&zip_xy_scaler 1 1` in `keyball44_right.overlay` — leave at 1/1; ratios below 1 make small movements jolty |
| Acceleration | sigmoid, `ACCELERATION_ALGORITHM=2` + `ACCELERATION_SENSITIVITY` (3) — sensitivity is the **maximum** multiplier, reached on hard flicks |
| Scroll speed | `CONFIG_PMW3610_SCROLL_TICK` (120; higher = slower) — ball travel per click is `TICK * 25.4 / CPI` mm, currently 1.9mm |

The top-right key exists for one-handed use: the bottom-left thumb key and the
momentary scroll under MOD both need the left hand, which is no help when the right
hand is on the ball by itself. It is a toggle rather than a momentary layer for the
same reason — the hand has to be free to move the ball once scrolling is on. Both
toggles drive the same layer, so either one turns the other off.

**Before tuning anything, check how you are holding it.** The sensor is
side-mounted and images the ball from one side, so a thumb resting on *top* of
the ball presses it away from the lens and out of focus — tracking simply stops
until the pressure eases, at any speed, seemingly at random. Drive the ball from
the side. This accounted for essentially every "it misses movement" symptom
here, after a great many settings had been changed chasing it.

**Then check the ball spins freely.** Weeks of pointer settings
were once spent on what turned out to be a ball sticking in its bearings — the
sensor was correctly reporting no rotation, and no setting can fix that. Flick the
reseated ball: it should coast for a second or more and feel glassy. Clean with
isopropyl alcohol only; household or disinfecting wipes leave a film that causes
exactly this.

Two curves are running: macOS's, and the firmware's sigmoid on top of it. That is
deliberate — it is what lets the macOS tracking slider sit low, for precision when
nudging, without long movements running out of ball. Tune in this order:

1. **Base speed** — the macOS tracking slider, set by how precise **short**
   movements feel. Lower it until slow tracking is accurate; ignore reach.
2. **Reach** — `CONFIG_PMW3610_ACCELERATION_SENSITIVITY`, raised until a flick
   crosses the screen. It is the ceiling of the multiplier, so 3 means a hard
   flick moves at most 3× as far as the same ball travel would at a crawl.
3. **Resolution** — `CONFIG_PMW3610_CPI`, only if slow movement is stepping rather
   than merely fast. Higher CPI is finer, not just quicker (see below), and
   `SCROLL_TICK` has to move with it.

Notes, because several of these are traps:

- **Leave `CONFIG_PMW3610_CPI_DIVIDOR` at 1.** It is not a sensor setting — it is an
  integer divide applied to every motion report. Any value above 1 truncates small
  deltas to zero, so slow ball movement is discarded entirely and the pointer only
  responds once you move fast enough to clear the divisor. Set speed with CPI, which
  the sensor applies in hardware without dropping counts.
- **`SCROLL_TICK` is tied to `CPI`.** Scroll mode ignores the divisor and counts raw
  sensor ticks, so halving CPI halves scroll speed unless `SCROLL_TICK` comes down
  with it. The `zip_xy_scaler` does *not* affect scroll — it only matches
  `REL_X`/`REL_Y` — so trimming speed there leaves scrolling alone.
- **High CPI here, speed turned down in macOS.** Jerky slow movement is granularity:
  one count is the smallest step the pointer can take, so at 400 CPI (0.064mm per
  count) a slow roll moves the cursor a whole pixel at a time. 1600 CPI is 0.016mm
  per count — four times finer.

  Scaling back down must not happen in firmware. Both knobs available here are
  integer divides: `CPI_DIVIDOR` discards the remainder, and `zip_xy_scaler` keeps it
  but still emits whole pixels, so **any ratio below 1 makes some reports emit zero**
  and puts the stepping right back. macOS accumulates fractionally inside its own
  acceleration curve, so turning the tracking slider down costs nothing. Keep the
  scaler at `1 1`.

  CPI does not change the report *rate* — one report per poll either way — so raising
  it adds no BLE traffic and cannot bring back the 250Hz pointer lag.
- **Two separate dials, don't confuse them.** Base speed (the macOS slider, plus CPI)
  sets how fast slow movement is; acceleration sets how much *extra* fast movement
  gets. Reports of 1 count or less skip acceleration entirely, so raising sensitivity
  never coarsens precise movement. "Can't cross the screen" → raise sensitivity.
  "Too twitchy when nudging" → lower the slider.
- **The two acceleration algorithms behave completely differently.** `ALGORITHM=2`
  (sigmoid, in use here) reads speed in counts per millisecond between reports and
  gives `1 + (sensitivity-1)·S(0.25·(speed-10))` — bounded by sensitivity, so the
  setting is the maximum multiplier and raising it degrades gracefully. `ALGORITHM=1`
  (quadratic, `x + x²/(22-2·sensitivity)`) reads the *size* of a single report and is
  unbounded; at 800 CPI a hard flick is ~100 counts in one report, so its multiplier
  runs away. That is what made sensitivity 5 unusable, and it divides by zero at 11.
  A sensitivity number carried across from one algorithm to the other means nothing.
- **Where the sigmoid's knee sits.** Halfway gain lands at 10 counts/ms, which at
  800 CPI is 12.5 in/s of ball surface — a real flick, not a fast normal movement.
  Below ~2 in/s the multiplier is within a few percent of 1× and truncation to whole
  pixels rounds most of it away. Moving the knee means editing `pmw3610.c`; the only
  exposed knob is the ceiling.
- **Pointer lags over Bluetooth?** Report rate, not speed. The polling options are
  misnamed: `250` and `125_SW` both run the sensor at 250Hz, and `125_SW` merely
  discards every other report and folds it into the next (hence its extra latency).
  Only plain `CONFIG_PMW3610_POLLING_RATE_125` slows the sensor itself. The ball is on
  the central, so its reports go straight to the host — but at the negotiated
  7.5–11.25ms connection interval that link carries only ~90–130 events/sec and cannot
  drain 250 reports/sec, so the backlog shows up as lag that grows while you keep
  moving. 125 is the setting for wireless use; 250 is fine with the right half on USB.
- **Cursor freezing for a tenth of a second at a time while you move?** That is BLE
  slave latency, not the sensor. `CONFIG_BT_PERIPHERAL_PREF_LATENCY` in
  `config/keyball44.conf` is how many connection events the radio may skip; the
  worst-case silent gap is `(latency + 1) × interval`. The stock 16 at an 11.25ms
  interval permits **191ms of nothing**, and ZMK never renegotiates it when the
  pointer becomes active. It is 0 here, which keeps the radio present every interval
  at some battery cost. Intermediate values and the gap they allow: 2 → 34ms,
  4 → 56ms, 8 → 101ms.

  To measure rather than guess: screen-record a slow circle, then step through the
  frames and diff consecutive ones — the cursor is the only thing moving, so frames
  with no change are frames where it did not move. Beware that the recorder can drop
  frames too, which looks identical.
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
- **NUM** (hold the second left thumb key, the one whose keycap says *command*):
  right-hand numpad (`789 / 456 / 123`, `0` on SPACE),
  ⌥⇧S/D/F on the left home row, ⌘SPACE (Spotlight) on the BSPC thumb, and the
  terminal control keys macOS has no room for because ⌘ owns those chords:

  | Key | Sends | For |
  | --- | --- | --- |
  | `C` | `Ctrl+C` | interrupt |
  | `R` | `Ctrl+R` | reverse history search |

  Nothing destructive goes on NUM's left half. NUM (layer 4) outranks NAV (layer 1),
  so any press that catches both keys fires left-half NUM bindings during ordinary
  `mod+C` / `mod+V` / `mod+D` use. The two are no longer neighbours in the thumb
  cluster, which makes that rarer without making it impossible.
- **SYS** (hold NUM + SYM together — the second and fifth left thumb keys, which
  now sit at opposite ends of the cluster: reach it with thumb and index finger):

  | Key | Action |
  | --- | --- |
  | `A` `S` `D` `F` `G` | select Bluetooth profile 0–4 |
  | `Q` `W` `E` | output USB / BLE / toggle |
  | `X` / `C` | clear this profile's pairing / clear **all** profiles |
  | `Z` / outer bottom-left (`⌘`) | `sys_reset` / `bootloader` — left keys act on the left half, right keys on the right |
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
the two thumb keys (NUM + SYM) and press the outer key of the bottom letter row (the
left one, `⌘`, reboots the left half; the right one, the left-click key, the right).

### 3. Pair

Turn both halves on. They pair to each other automatically (**right is central**).
Then on the Mac: System Settings → Bluetooth → connect to **Keyball44**. The right
half is the one that talks to the computer — plug USB into it if you prefer wired.

Five Bluetooth profiles are available (0–4): hold NUM+SYM together (the SYS layer)
and press `A`–`G` to switch, `X` to clear the current profile's pairing.

### 4. If something's weird

- A half dark and dead after sitting idle, only the power switch revives it →
  deep sleep with no wake source. Both halves sleep after 15 minutes unplugged
  (`CONFIG_ZMK_SLEEP` in `config/keyball44.conf`; USB power suppresses it), and ZMK
  arms the key matrix as the wake source only if
  `kscan0` in `keyball44.dtsi` declares `wakeup-source;`. Without it the matrix is
  suspended and its pins disconnected before power-off, so no keypress can reach
  the chip. On a firmware that has it, a keypress wakes the half by resetting it —
  expect a couple of seconds and one swallowed keystroke.
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
