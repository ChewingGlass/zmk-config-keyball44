#!/usr/bin/env bash
# Watch for a nice!nano in bootloader mode and copy firmware onto it.
#
#   ./flash.sh all      first-time flash: settings_reset on both halves, then
#                       the real firmware on each (walks you through it)
#   ./flash.sh left     keyball44_left.uf2
#   ./flash.sh right    keyball44_right.uf2  (the trackball half)
#   ./flash.sh reset    settings_reset.uf2   (same file for either half)
#   ./flash.sh debug    keyball44_right_debug.uf2 — diagnostic build with USB
#                       logging and no ZMK Studio; see ./capture-log.sh
#
# To get a half into bootloader mode: pop the protective cover off the display
# and double-press the reset button on the PCB directly underneath the screen.
# Once this firmware is on, that's no longer needed — hold the two thumb keys
# (NUM + SYM) and press the outer Shift key instead (left Shift reboots the
# left half, right Shift the right).
#
# Build the .uf2 files first with ./build.sh.

set -uo pipefail
cd "$(dirname "$0")"

FW_DIR="$PWD/firmware"
MOUNT_TIMEOUT=${MOUNT_TIMEOUT:-300}   # how long to wait for a double-press, seconds
REBOOT_TIMEOUT=${REBOOT_TIMEOUT:-60}  # how long to wait for the board to reboot after writing

# The bootloader drive is normally /Volumes/NICENANO, but macOS appends a digit
# if a stale mount from a previous flash is still hanging around.
#
# Testing for a directory is NOT enough. When the board reboots it yanks the USB
# device out from under the filesystem, and macOS can leave the mount point
# behind as an ordinary empty directory on the boot disk. That leftover looks
# exactly like a mounted drive to `[ -d ]`, so a copy into it silently succeeds,
# writes the firmware to the internal SSD, and never touches the keyboard.
# INFO_UF2.TXT is written by the bootloader itself, so its presence is proof the
# real device is there.
find_drive() {
    local v
    for v in /Volumes/NICENANO*; do
        [ -f "$v/INFO_UF2.TXT" ] || continue
        printf '%s\n' "$v"
        return 0
    done
    return 1
}

# A leftover mount point also steals the name, so the next real mount lands at
# "/Volumes/NICENANO 1" and the boot disk slowly fills with firmware images.
warn_stale_mountpoint() {
    local v
    for v in /Volumes/NICENANO*; do
        [ -d "$v" ] || continue
        [ -f "$v/INFO_UF2.TXT" ] && continue
        echo "note: '$v' is a leftover mount point on the boot disk, not a device." >&2
        echo "      Remove it so the next flash mounts under the right name:" >&2
        echo "        sudo rm -rf '$v'" >&2
    done
}

# Progress goes to stderr so the drive path stays the only thing on stdout.
wait_for_drive() {
    local deadline=$((SECONDS + MOUNT_TIMEOUT)) drive
    while ((SECONDS < deadline)); do
        if drive=$(find_drive); then
            printf '%s\n' "$drive"
            return 0
        fi
        sleep 0.5
    done
    return 1
}

wait_for_unmount() {
    local deadline=$((SECONDS + REBOOT_TIMEOUT))
    while ((SECONDS < deadline)); do
        find_drive >/dev/null || return 0
        sleep 0.5
    done
    return 1
}

flash_one() {
    local uf2=$FW_DIR/$1.uf2 what=$2 drive err

    if [ ! -f "$uf2" ]; then
        echo "missing $uf2 — run ./build.sh first" >&2
        return 1
    fi

    echo
    echo "==> $what"

    # A board already sitting in the bootloader is the one being flashed, not a
    # leftover — a successful flash ends with the drive gone, so nothing stale
    # survives a completed step.
    if drive=$(find_drive); then
        echo "    $drive already mounted"
    else
        echo "    double-press the reset button (under the display cover)..."
        if ! drive=$(wait_for_drive); then
            echo "    timed out after ${MOUNT_TIMEOUT}s — no NICENANO drive appeared" >&2
            return 1
        fi
    fi

    echo "    writing $(basename "$uf2") to $drive"
    # -X skips extended attributes. The board reboots the moment the last block
    # of the UF2 lands, so a plain cp always fails its trailing xattr pass with
    # "Device not configured" even on a perfectly good flash. The drive going
    # away is the real success signal, not cp's exit status — but keep cp's
    # message around, because it is the only diagnostic when a write truly fails.
    err=$(cp -X "$uf2" "$drive/" 2>&1)

    if wait_for_unmount; then
        echo "    done — board rebooted"
        return 0
    fi

    echo "    warning: $drive still mounted after ${REBOOT_TIMEOUT}s" >&2
    [ -n "$err" ] && echo "    cp: $err" >&2
    if [ -e "$drive/$(basename "$uf2")" ]; then
        echo "    the .uf2 is on the drive but the board did not reboot" >&2
    else
        echo "    the .uf2 never landed — the write failed, nothing was flashed" >&2
    fi
    return 1
}

flash_all() {
    echo "First-time flash. Four double-presses total, two per half."
    echo "settings_reset wipes stored pairing so the halves find each other cleanly."

    flash_one settings_reset "settings_reset -> LEFT half"  || return 1
    flash_one settings_reset "settings_reset -> RIGHT half" || return 1

    echo
    echo "Now power-cycle both halves and wait ~10s."
    read -r -p "Press Enter when both are back on... " _

    flash_one keyball44_left  "keyball44_left -> LEFT half"   || return 1
    flash_one keyball44_right "keyball44_right -> RIGHT half" || return 1

    echo
    echo "All four written. Turn both halves on — they pair to each other"
    echo "automatically (right is central), then connect to 'Keyball44' in"
    echo "System Settings -> Bluetooth."
}

warn_stale_mountpoint

case "${1:-}" in
    all)   flash_all ;;
    left)  flash_one keyball44_left  "keyball44_left -> LEFT half" ;;
    right) flash_one keyball44_right "keyball44_right -> RIGHT half" ;;
    reset) flash_one settings_reset  "settings_reset" ;;
    debug) flash_one keyball44_right_debug "keyball44_right_debug -> RIGHT half (USB logging, no Studio)" ;;
    *)     echo "Usage: $0 [all|left|right|reset|debug]"; exit 1 ;;
esac
