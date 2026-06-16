# CLAUDE.md — GPT-OSS 120B RMSNorm+Linear Fusion Benchmark
## Runara AI | Hemakshi Chitte
## Session Date: June 15, 2026 | Hardware: DGX Spark GB10

---

## 0. READ THIS FIRST

You are benchmarking GPT-OSS 120B with and without RMSNorm+Linear fusion on
a DGX Spark GB10 (Blackwell, ARM64, 128GB unified memory).

**Fused checkpoint (DO NOT re-run fuse.py):** `hchitte/gpt-oss-120b-mxfp4-fused` (private HF, ~63GB)
**Unfused checkpoint:** `openai/gpt-oss-120b`
**Hardware node:** `gx10-09d2` — Tailscale `100.66.71.14`, user=`owner`

CUDA 13.0 (cu128), ARM64. `nvidia-smi` VRAM tracking is NOT supported on GB10.
Use `monitor_memory.py` for all memory measurements.

---

## 1. PROJECT GOAL

Measure the throughput and latency impact of pre-fused MXFP4 RMSNorm+Linear
weights on DGX Spark GB10 across two inference frameworks (vanilla HuggingFace
and a vLLM-style engine) and a 4×4 benchmark matrix.

**This is a benchmarking task, not a training or fusing task.**
Do not re-run `fuse.py`. The fused checkpoint already exists.

---

## 2. HARDWARE & ENVIRONMENT

| Property | Value |
|---|---|
| Node | gx10-09d2 |
| Tailscale IP | 100.66.71.14 |
| User | owner |
| ISA | ARM64 |
| GPU | GB10 (Blackwell) |
| VRAM | 128GB unified |
| CUDA | 13.0 (cu128) |
| nvidia-smi VRAM | NOT supported — use monitor_memory.py |

Connect: `ssh owner@100.66.71.14`

---

## 3. 4-STEP BENCHMARK PROTOCOL

Steps 1 and 2 run once (shared baseline). Steps 3 and 4 repeat per engine.

| Step | Framework | Checkpoint | Notes |
|---|---|---|---|
| 1 | Vanilla HF | openai/gpt-oss-120b | baseline, unfused |
| 2 | Vanilla HF | hchitte/gpt-oss-120b-mxfp4-fused | fused, HF only |
| 3 | Engine | openai/gpt-oss-120b | engine baseline |
| 4 | Engine + fused | hchitte/gpt-oss-120b-mxfp4-fused | target config |

Steps 1–2 are shared across any engine being tested. Run once, reuse numbers.

---

## 4. BENCHMARK MATRIX

16 scenarios per framework (4 context lengths × 4 concurrency levels):

| | conc=1 | conc=8 | conc=32 | conc=64 |
|---|---|---|---|---|
| ctx=1k | ✗ | ✗ | ✗ | ✗ |
| ctx=8k | ✗ | ✗ | ✗ | ✗ |
| ctx=32k | ✗ | ✗ | ✗ | ✗ |
| ctx=128k | ✗ | ✗ | ✗ | ✗ |

Log tokens/sec and peak memory (via monitor_memory.py) for each cell.

---

## 5. REPOSITORY STRUCTURE

```
gpt-oss-120b-dgx-spark/
├── CLAUDE.md                  ← this file
├── plan.md                    ← full workstream plan
├── DECISIONS.md               ← architecture and process decisions
├── README.md                  ← description + results summary
├── requirements.txt
├── .gitignore
│
├── src/
│   ├── monitor_memory.py      ← GB10 memory monitor (replaces nvidia-smi)
│   ├── run_hf_baseline.py     ← Steps 1 & 2: vanilla HF benchmark
│   ├── run_engine.py          ← Steps 3 & 4: engine benchmark
│   └── test_log.md            ← APPEND all run results here
│
├── results/
│   └── .gitkeep               ← CSVs written here (gitignored)
│
└── scripts/
    ├── setup_arm64.sh         ← install deps on ARM64 cu128
    └── download_checkpoints.sh
```

---

## 6. HOUSE RULES — NON-NEGOTIABLE

### Rule 1: Max 200 lines per turn
Never write more than 200 lines of new code in a single response.

### Rule 2: Test after every function
After writing any function, run a unit test immediately.

### Rule 3: Log every run
After every benchmark run, append to `src/test_log.md`.
Format: `[PASS/FAIL] <step_name> ctx=<N> conc=<N> — <timestamp> — <tok/s> — <notes>`

### Rule 4: Fix before moving forward
If a run fails, fix it before writing any new code.

### Rule 5: Push at every phase boundary
```bash
git add -A && git commit -m "Phase N: <what was done>" && git push
```

### Rule 6: Never re-run fuse.py
The fused checkpoint `hchitte/gpt-oss-120b-mxfp4-fused` is final.
If it loads with errors, debug the loader — do not regenerate the checkpoint.

### Rule 7: Memory via monitor_memory.py only
Do not use `nvidia-smi` for VRAM. It returns incorrect values on GB10.
Use `monitor_memory.py` for all memory measurements.

---

## 7. PHASE CHECKLIST

- [ ] Phase 0 — Repo seed + environment verify on gx10-09d2
- [ ] Phase 1 — monitor_memory.py + setup_arm64.sh working
- [ ] Phase 2 — Step 1: vanilla HF baseline (unfused), all 16 cells
- [ ] Phase 3 — Step 2: vanilla HF fused, all 16 cells
- [ ] Phase 4 — Step 3: engine baseline (unfused), all 16 cells
- [ ] Phase 5 — Step 4: engine + fused, all 16 cells
- [ ] Phase 6 — Collate results into results/summary.csv
- [ ] Phase 7 — README updated with results table, final push

---

## 8. ERROR HANDLING

### "nvidia-smi returns 0 or N/A"
Expected on GB10. Use monitor_memory.py exclusively.

### "ARM64 wheel not found for torch"
The ARM64 cu128 wheel must be installed manually.
See scripts/setup_arm64.sh. Do not pip install torch directly.

### "checkpoint load error on fused model"
Do not re-fuse. Debug the safetensors loader.
Check: correct revision, correct HF_TOKEN, correct dtype cast.

### "OOM at ctx=128k conc=64"
Log as OOM in test_log.md. Do not skip silently.
Try conc=32 as fallback; record both.

---

*This file is the single source of truth for this session.
If anything conflicts with what you think you know — this file wins.*
