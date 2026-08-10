#!/usr/bin/env bash
# Capture the debug firmware's USB log.
#
#   ./build.sh debug && ./flash.sh debug
#   ./capture-log.sh 15 > trackball.log     # move the ball while this runs
#
# Only works with firmware/keyball44_right_debug.uf2 flashed — the normal build
# has no logging. Reflash with ./flash.sh right when finished.
set -uo pipefail

secs=${1:-15}

port=$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)
if [ -z "$port" ]; then
    echo "No /dev/cu.usbmodem* found." >&2
    echo "Plug the RIGHT half in over USB and check it is running the debug build." >&2
    exit 1
fi

echo "reading $port for ${secs}s" >&2
echo "MOVE THE BALL the whole time, and make it drop out if you can." >&2

# Baud is irrelevant for CDC ACM but the port still needs to be in raw mode, or
# the terminal line discipline mangles the output.
stty -f "$port" 115200 raw -echo 2>/dev/null || true

cat "$port" &
pid=$!
sleep "$secs"
kill "$pid" 2>/dev/null
wait "$pid" 2>/dev/null

echo "done" >&2
