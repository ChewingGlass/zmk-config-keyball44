# Noah's Keyball44 — corne layout + dactyl trackball features

ZMK firmware for the MochuKeeb Keyball44 (nice!nano v2, nice!view displays, PMW3610
trackball). This branch (`keyball44-noah`) ports my corne layout and rebuilds the two
killer features from my old dactyl:

- **Auto-mouse clicks** — move the trackball, and for the next 400ms **U/J = left
  click, I/K = right click**. Stop touching the ball and they go back to typing.
- **Sticky selection** — emacs-style mark mode: `mod+space` arms it, then the nav keys
  extend the selection until you copy/cut/paste or release `mod`.

All shortcuts are macOS-flavored (Cmd-based).

## Base layer

```
ESC    Q  W  E  R  T   │   Y  U  I  O  P   BSPC
CAPS   A  S  D  F  G   │   H  J  K  L  ;   '
LSHFT  Z  X  C  V  B   │   N  M  ,  .  /   RSHFT
                       │
SCROLL TAB ENTER MOD SYM │ BSPC SPACE   ◉ball  DEL
 tog   ⇧alt ⇧num  ⇧nav ⇧ │              (corner key)
```

Left thumb row, left to right:

| Key | Tap | Hold |
| --- | --- | --- |
| bottom-left | toggle trackball **scroll mode** (tap again to exit) | — |
| next | `TAB` | `Left Alt` |
| Enter key | `ENTER` | **NUM** layer (numpad) |
| **MOD** | — | **NAV** layer (your old `LM(1, GUI)` key) |
| inner | — | **SYM** layer |

Right side: `BSPC` + `SPACE` thumbs, `DEL` on the corner key past the trackball,
`ENTER` is on the left thumb now (tap the NUM key).

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
| Left / right click | `U` or `J` / `I` or `K` within 400ms of ball movement |
| Scroll mode (locked) | tap the bottom-left key; tap again to exit |
| Scroll (momentary) | hold MOD |
| Click timeout | `CONFIG_PMW3610_AUTOMOUSE_TIMEOUT_MS` in `config/boards/shields/keyball_nano/keyball44_right.conf` |
| Pointer speed | `CONFIG_PMW3610_CPI` (1200), same file |
| Scroll speed | `CONFIG_PMW3610_SCROLL_TICK` (32; higher = slower) |

A SNIPE (precision) layer exists for the driver but has no key bound — bind `&mo SNIPE`
somewhere in `config/keyball44.keymap` if you want it.

## Other layers

- **SYM** (hold inner-left thumb): `! @ # $ %` / `~ \` { } [` on the left,
  `^ & * + =` / `] ( ) ' "` on the right, `- _ |` on the bottom, `_`/`-` on the
  right thumbs. Same as the corne's symbol layer.
- **NUM** (hold the Enter key): right-hand numpad (`789 / 456 / 123`, `0` on SPACE),
  ⌥⇧S/D/F on the left home row, ⌘SPACE (Spotlight) on the BSPC thumb.
- **SYS** (hold NUM + SYM together): Bluetooth profile select/clear, USB/BLE output
  toggle, F1–F12, and `bootloader`/`reset` (bottom-left keys affect the left half,
  bottom-right keys the right half).

## Day-1 install

### 0. Build the firmware

Push this branch to a GitHub repo you own (a fork of this repo works) and GitHub
Actions builds it automatically — check the **Actions** tab, open the latest run, and
download the `firmware` artifact. It contains:

- `keyball44_left ... .uf2` — left half (the central/USB half)
- `keyball44_right ... .uf2` — right half
- `settings_reset ... .uf2` — pairing reset

> On a fresh fork, GitHub disables workflows until you click **"I understand my
> workflows, enable them"** in the Actions tab once.

### 1. (First time / pairing problems) flash `settings_reset`

Flash it to **both** halves, power-cycle both, wait ~10s. This wipes stored pairing
so the halves can find each other cleanly.

### 2. Flash each half

For each half, **plug it in over USB** and **double-tap the reset button** — it mounts
as a USB drive called `NICENANO`. Drag the matching `.uf2` onto it; it flashes and
reboots itself:

1. Left half ← `keyball44_left ... .uf2`
2. Right half ← `keyball44_right ... .uf2`

### 3. Pair

Turn both halves on. They pair to each other automatically (left is central). Then on
the Mac: System Settings → Bluetooth → connect to **Keyball44**. The left half is the
one that talks to the computer — plug USB into it if you prefer wired.

Five Bluetooth profiles are available: hold NUM+SYM and use the top-left row
(`BT_SEL 0–3`, `BT_CLR` clears the current profile's pairing).

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
