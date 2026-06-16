# GPT-OSS 120B — RMSNorm+Linear Fusion Benchmark on DGX Spark GB10

Benchmark suite for measuring the throughput and latency impact of pre-fused
MXFP4 RMSNorm+Linear weights on a DGX Spark GB10 node (Blackwell, ARM64,
128GB unified memory).

---

## Hardware Target

| Property | Value |
|---|---|
| Node | gx10-09d2 |
| Tailscale IP | 100.66.71.14 |
| GPU | GB10 Blackwell |
| Memory | 128GB unified |
| ISA | ARM64 |
| CUDA | 13.0 (cu128) |

---

## Checkpoints

| Checkpoint | Notes |
|---|---|
| `openai/gpt-oss-120b` | Unfused baseline (~240GB) |
| [`hchitte/gpt-oss-120b-mxfp4-fused`](https://huggingface.co/hchitte/gpt-oss-120b-mxfp4-fused) | Pre-fused MXFP4 (~63GB, private) |

The fused checkpoint was produced by a prior fuse.py run and is treated as
immutable. Do not re-run fuse.py.

---

## Benchmark Matrix

16 scenarios per framework: context ∈ {1k, 8k, 32k, 128k} × concurrency ∈ {1, 8, 32, 64}

---

## Results

*Results will be populated after Phase 7.*

---

## Quick Start

```bash
ssh owner@100.66.71.14
git clone https://github.com/hemoxiChloride/gpt-oss-120b-dgx-spark
cd gpt-oss-120b-dgx-spark
bash scripts/setup_arm64.sh
source .venv/bin/activate
python src/monitor_memory.py --check
```

---

## Repo Layout

```
src/            benchmark scripts + monitor_memory.py
scripts/        setup_arm64.sh, download_checkpoints.sh
results/        CSVs (gitignored except .gitkeep)
```

See [plan.md](plan.md) for the full phase-by-phase workstream.
See [DECISIONS.md](DECISIONS.md) for architectural decisions.
