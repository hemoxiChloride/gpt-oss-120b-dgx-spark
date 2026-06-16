#!/usr/bin/env bash
set -e

echo "=== venv check ==="
if [ -z "$VIRTUAL_ENV" ]; then
    echo "FAIL: no active venv detected. Run: source ~/venv/bin/activate"
    exit 1
fi
echo "venv: $VIRTUAL_ENV  OK"

echo ""
echo "=== attempt 1: sglang stable ==="
INSTALLED=0
if pip install sglang 2>&1; then
    INSTALLED=1
    echo "stable install succeeded"
else
    echo "stable install failed — falling through to pre-release"
fi

if [ $INSTALLED -eq 0 ]; then
    echo ""
    echo "=== attempt 2: sglang pre-release ==="
    if pip install sglang --pre 2>&1; then
        INSTALLED=1
        echo "pre-release install succeeded"
    else
        echo ""
        echo "FAIL: both stable and pre-release sglang installs failed."
        echo "Next step: build sglang from source for SM12.1 ARM64."
        echo "  git clone https://github.com/sgl-project/sglang"
        echo "  cd sglang && pip install -e '.[all]'"
        exit 1
    fi
fi

echo ""
echo "=== verifying sglang install ==="
python3 -c "
import sglang
print('sglang.version =', sglang.__version__)
" || { echo "FAIL: sglang import failed — check install logs above."; exit 1; }

echo ""
echo "PASS"
