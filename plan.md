# Plan — GPT-OSS 120B DGX Spark GB10 Benchmark Workstream
## Runara AI | Hemakshi Chitte | June 15, 2026

---

## Objective

Quantify the latency and throughput delta of pre-fused MXFP4 RMSNorm+Linear
weights (checkpoint: `hchitte/gpt-oss-120b-mxfp4-fused`) vs. the stock
`openai/gpt-oss-120b` checkpoint on a DGX Spark GB10 node, across two
inference frameworks and a 4×4 context/concurrency matrix (16 scenarios each).

---

## Hardware

- Node: `gx10-09d2` (Tailscale `100.66.71.14`, user `owner`)
- GPU: GB10 Blackwell, 128GB unified memory, ARM64, CUDA 13.0 (cu128)
- Memory monitoring: `src/monitor_memory.py` (nvidia-smi not reliable on GB10)

---

## Checkpoints

| Checkpoint | Source | Size | Notes |
|---|---|---|---|
| `openai/gpt-oss-120b` | HF public | ~240GB | unfused baseline |
| `hchitte/gpt-oss-120b-mxfp4-fused` | HF private | ~63GB | MXFP4, fused — DO NOT re-create |

---

## Phase 0 — Repo Seed + Environment Verify (30 min)

**Goal:** working SSH to node, repo cloned, Python env healthy.

Tasks:
- SSH into gx10-09d2 via Tailscale
- Clone this repo
- Run `scripts/setup_arm64.sh` to install ARM64 cu128 torch + deps
- Verify: `python -c "import torch; print(torch.cuda.is_available())"`
- Verify: `python src/monitor_memory.py --check`

Gate: torch CUDA available, monitor_memory.py prints a non-zero memory reading.

---

## Phase 1 — Monitor + Infra (45 min)

**Goal:** `monitor_memory.py` streams GB10 unified memory to CSV; helper
utilities wired up.

Tasks:
- Write `src/monitor_memory.py` — polls GB10 memory every 0.5s, writes CSV
- Write `scripts/setup_arm64.sh`
- Write `scripts/download_checkpoints.sh`
- Unit test monitor_memory.py in isolation (no GPU needed)

Gate: `python src/monitor_memory.py --duration 5 --out /tmp/mem_test.csv`
produces a valid CSV with timestamps and memory columns.

---

## Phase 2 — Step 1: Vanilla HF Baseline (unfused) (2 hr)

**Goal:** complete 4×4 matrix using vanilla HF `generate()` with
`openai/gpt-oss-120b`.

Tasks:
- Write `src/run_hf_baseline.py` with `--checkpoint`, `--ctx`, `--conc` flags
- Run all 16 cells: ctx ∈ {1024, 8192, 32768, 131072} × conc ∈ {1, 8, 32, 64}
- Log each cell to `src/test_log.md` and write row to `results/hf_unfused.csv`
- Flag OOM cells without skipping silently

Gate: `results/hf_unfused.csv` has 16 rows (or OOM annotations).

---

## Phase 3 — Step 2: Vanilla HF Fused (2 hr)

**Goal:** same matrix with `hchitte/gpt-oss-120b-mxfp4-fused`.

Tasks:
- Reuse `src/run_hf_baseline.py` with `--checkpoint hchitte/gpt-oss-120b-mxfp4-fused`
- Verify fused checkpoint loads cleanly before running matrix
- Log each cell; write `results/hf_fused.csv`

Gate: `results/hf_fused.csv` has 16 rows (or OOM annotations).
Delta table (fused vs unfused) written to `results/hf_delta.csv`.

---

## Phase 4 — Step 3: Engine Baseline (unfused) (2 hr)

**Goal:** 4×4 matrix with inference engine on `openai/gpt-oss-120b`.

Tasks:
- Write `src/run_engine.py` with `--engine`, `--checkpoint`, `--ctx`, `--conc`
- Start engine server; run 16-cell sweep
- Log each cell; write `results/engine_unfused.csv`

Gate: `results/engine_unfused.csv` has 16 rows.

---

## Phase 5 — Step 4: Engine + Fused (2 hr)

**Goal:** 4×4 matrix with engine on `hchitte/gpt-oss-120b-mxfp4-fused`.

Tasks:
- Reuse `src/run_engine.py` with fused checkpoint
- Log each cell; write `results/engine_fused.csv`

Gate: `results/engine_fused.csv` has 16 rows.
Delta table written to `results/engine_delta.csv`.

---

## Phase 6 — Collate Results (30 min)

**Goal:** single summary CSV + console table across all 4 configs.

Tasks:
- Write `src/collate.py` — merges 4 CSVs into `results/summary.csv`
- Print markdown table: rows = (framework, fused/unfused), cols = context×conc cells
- Compute fusion speedup ratio per cell

Gate: `results/summary.csv` exists and is non-empty.

---

## Phase 7 — Final (20 min)

**Goal:** README updated, clean push, all phases green.

Tasks:
- Update `README.md` with results table from Phase 6
- Confirm all phase gates met; check `src/test_log.md` has entries for every run
- `git add -A && git commit -m "Phase 7: final results" && git push`

Gate: clean push, no uncommitted changes.

---

## Definition of Done

- [ ] 16-cell HF unfused results in `results/hf_unfused.csv`
- [ ] 16-cell HF fused results in `results/hf_fused.csv`
- [ ] 16-cell engine unfused results in `results/engine_unfused.csv`
- [ ] 16-cell engine fused results in `results/engine_fused.csv`
- [ ] `results/summary.csv` with fusion speedup ratios
- [ ] `src/test_log.md` has entry for every single run
- [ ] `README.md` has results table
- [ ] All code pushed, no uncommitted changes

---

## Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| OOM at ctx=128k conc=64 | High | Log as OOM; try conc=32 fallback |
| ARM64 wheel not on PyPI | Medium | Use pre-built nightly from scripts/setup_arm64.sh |
| Fused checkpoint load error | Low | Debug loader; never re-fuse |
| Tailscale disconnect mid-run | Low | Use tmux/screen for all long runs |
| HF_TOKEN missing on node | Medium | Export before any download step |
