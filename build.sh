#!/usr/bin/env bash
# Build keyball44 firmware locally. Output lands in ./firmware/.
#
# First-time setup (downloads ~2GB of ZMK/Zephyr sources + toolchain):
#   ./build.sh setup
# Every build after that:
#   ./build.sh
#
# Requires Homebrew. Everything else (cmake, ninja, dtc, uv, python, west,
# Zephyr SDK) is installed by `setup`.

set -euo pipefail
cd "$(dirname "$0")"

SDK_VERSION=0.16.8
SDK_DIR="$HOME/zephyr-sdk-$SDK_VERSION"
WEST=.venv/bin/west

setup() {
    brew install cmake ninja dtc uv

    if [ ! -x .venv/bin/python ]; then
        uv venv --python 3.11 .venv
    fi
    uv pip install --python .venv/bin/python west

    if [ ! -d .west ]; then
        $WEST init -l config
    fi
    $WEST update --narrow --fetch-opt=--depth=1
    $WEST zephyr-export
    uv pip install --python .venv/bin/python -r zephyr/scripts/requirements-base.txt
    # setuptools<81: nanopb's generator (ZMK Studio protobufs) still imports pkg_resources
    uv pip install --python .venv/bin/python 'setuptools<81' protobuf grpcio-tools

    if [ ! -d "$SDK_DIR" ]; then
        echo "Downloading Zephyr SDK $SDK_VERSION (ARM toolchain)..."
        curl -sSL -o /tmp/zephyr-sdk-min.tar.xz \
            "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$SDK_VERSION/zephyr-sdk-${SDK_VERSION}_macos-$(uname -m | sed s/arm64/aarch64/)_minimal.tar.xz"
        tar xf /tmp/zephyr-sdk-min.tar.xz -C "$HOME"
        rm /tmp/zephyr-sdk-min.tar.xz
        "$SDK_DIR/setup.sh" -t arm-zephyr-eabi -c
    fi
    echo "Setup complete. Run ./build.sh to build."
}

build_target() {
    local name=$1 shield=$2; shift 2
    echo "=== Building $name ==="
    $WEST build -s zmk/app -d "build/$name" -b nice_nano_v2 "$@" -- \
        -DSHIELD="$shield" -DZMK_CONFIG="$PWD/config"
    cp "build/$name/zephyr/zmk.uf2" "firmware/$name.uf2"
}

build_all() {
    export PATH="$PWD/.venv/bin:$PATH"   # nanopb's protoc shebang needs the venv python
    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR="$SDK_DIR"
    mkdir -p firmware
    build_target keyball44_left  "keyball44_left nice_view_adapter nice_view"
    build_target keyball44_right "keyball44_right nice_view_adapter nice_view" -S studio-rpc-usb-uart
    build_target settings_reset  "settings_reset"
    echo
    echo "Done. Firmware in ./firmware/:"
    ls -la firmware/*.uf2
}

case "${1:-build}" in
    setup) setup ;;
    build) build_all ;;
    clean) rm -rf build firmware; echo "Removed build/ and firmware/" ;;
    *) echo "Usage: $0 [setup|build|clean]"; exit 1 ;;
esac
