#!/usr/bin/env bash
set -e

UNFUSED_DIR=/home/owner/models/gpt-oss-120b-unfused
FUSED_DIR=/home/owner/models/gpt-oss-120b-fused
MIN_FREE_GB=150

echo "=== venv check ==="
if [ -z "$VIRTUAL_ENV" ]; then
    echo "FAIL: no active venv. Run: source ~/venv/bin/activate"
    exit 1
fi
echo "venv: $VIRTUAL_ENV  OK"

echo ""
echo "=== HF_TOKEN check ==="
if [ -z "$HF_TOKEN" ]; then
    echo "FAIL: HF_TOKEN is not set. Required for private fused checkpoint."
    echo "  export HF_TOKEN=<your_token>"
    exit 1
fi
echo "HF_TOKEN: set  OK"

echo ""
echo "=== disk space check (need ${MIN_FREE_GB}GB free on /) ==="
FREE_KB=$(df / | awk 'NR==2 {print $4}')
FREE_GB=$(( FREE_KB / 1024 / 1024 ))
echo "free: ${FREE_GB}GB"
if [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then
    echo "FAIL: only ${FREE_GB}GB free on /; need at least ${MIN_FREE_GB}GB."
    exit 1
fi
echo "disk: OK"

echo ""
echo "=== downloading unfused checkpoint ==="
huggingface-cli download openai/gpt-oss-120b \
    --local-dir "$UNFUSED_DIR"
du -sh "$UNFUSED_DIR"

echo ""
echo "=== downloading fused checkpoint (private) ==="
huggingface-cli download hchitte/gpt-oss-120b-mxfp4-fused \
    --local-dir "$FUSED_DIR"
du -sh "$FUSED_DIR"

echo ""
echo "PASS"
