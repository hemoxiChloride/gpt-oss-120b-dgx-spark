#!/usr/bin/env bash
set -e

PASS=0

echo "=== arch check ==="
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "FAIL: expected aarch64, got $ARCH. This script must run on ARM64 (DGX Spark GB10)."
    exit 1
fi
echo "arch: $ARCH  OK"

echo ""
echo "=== nvcc --version ==="
nvcc --version

echo ""
echo "=== nvidia-smi ==="
# nvidia-smi VRAM may show N/A or Not Supported on GB10 — do not fail on this
nvidia-smi || echo "(nvidia-smi returned non-zero — expected on GB10 unified memory)"

echo ""
echo "=== python env report ==="
python3 src/check_env.py
PYEXIT=$?

echo ""
if [ $PYEXIT -eq 0 ]; then
    echo "PASS"
else
    echo "FAIL: check_env.py exited $PYEXIT"
    exit 1
fi
