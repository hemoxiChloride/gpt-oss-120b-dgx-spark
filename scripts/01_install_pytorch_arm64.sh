#!/usr/bin/env bash
set -e

echo "=== arch check ==="
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "FAIL: expected aarch64, got $ARCH. Run this on the DGX Spark GB10 node."
    exit 1
fi
echo "arch: $ARCH  OK"

echo ""
echo "=== installing PyTorch cu128 (ARM64) ==="
pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128

echo ""
echo "=== verifying PyTorch install ==="
VERIFY_OUT=$(python3 - <<'EOF'
import torch
print('torch.version       =', torch.__version__)
print('torch.cuda_version  =', torch.version.cuda)
print('cuda.is_available   =', torch.cuda.is_available())
print('device_capability   =', torch.cuda.get_device_capability())
print('device_name         =', torch.cuda.get_device_name(0))
EOF
)
echo "$VERIFY_OUT"

echo ""
if echo "$VERIFY_OUT" | grep -q "cuda.is_available   = False"; then
    echo "FAIL: torch.cuda.is_available() returned False — check CUDA driver and wheel version."
    exit 1
fi

echo "PASS"
