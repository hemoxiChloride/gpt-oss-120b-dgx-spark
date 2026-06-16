#!/usr/bin/env bash
set -e

echo "=== venv check ==="
if [ -z "$VIRTUAL_ENV" ]; then
    echo "FAIL: no active venv detected. Run: source ~/venv/bin/activate"
    exit 1
fi
echo "venv: $VIRTUAL_ENV  OK"

echo ""
echo "=== attempt 1: vllm stable ==="
INSTALLED=0
if pip install vllm 2>&1; then
    INSTALLED=1
    echo "stable install succeeded"
else
    echo "stable install failed — falling through to nightly"
fi

if [ $INSTALLED -eq 0 ]; then
    echo ""
    echo "=== attempt 2: vllm nightly (SM12.1 / ARM64) ==="
    if pip install vllm --pre \
            --extra-index-url https://wheels.vllm.ai/nightly 2>&1; then
        INSTALLED=1
        echo "nightly install succeeded"
    else
        echo ""
        echo "FAIL: both stable and nightly vllm installs failed."
        echo "Next step: build vllm from source for SM12.1 ARM64."
        echo "  git clone https://github.com/vllm-project/vllm"
        echo "  cd vllm && TORCH_CUDA_ARCH_LIST=12.1 pip install -e ."
        exit 1
    fi
fi

echo ""
echo "=== verifying vllm install ==="
python3 -c "
import vllm
print('vllm.version =', vllm.__version__)
" || { echo "FAIL: vllm import failed — check install logs above."; exit 1; }

echo ""
echo "PASS"
