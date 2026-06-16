# DECISIONS.md — GPT-OSS 120B DGX Spark Workstream
## Runara AI | Hemakshi Chitte

---

## Decision Log

---

### Decision 1 — New repo for DGX Spark workstream
**Date:** 2026-06-15
**Context:** The prior workstream (DeepSeek V4 Flash KV Latent Cache) lived in
`hemoxiChloride/deepseek-v4-flash-kv-latent-cache`. The DGX Spark GB10
benchmark is a distinct workstream: different model, different hardware,
different objective. Mixing them would pollute the commit history and phase
structure.
**Decision:** Create a new repo (`gpt-oss-120b-dgx-spark`) dedicated to the
GB10 benchmark. No code is shared between the two repos.
**Status:** Accepted.

---

### Decision 2 — Fused checkpoint referenced, not re-created
**Date:** 2026-06-15
**Context:** `hchitte/gpt-oss-120b-mxfp4-fused` (~63GB, private HF) was
produced by a prior `fuse.py` run on a different node. Re-running `fuse.py` on
the GB10 would consume ~4–6 hours and introduce risk of producing a different
artifact.
**Decision:** Treat the existing fused checkpoint as immutable ground truth.
`fuse.py` is not checked into this repo. All benchmark steps load the checkpoint
from HF; none regenerate it.
**Status:** Accepted.

---

### Decision 3 — ARM64 + 128GB unified memory as primary constraints
**Date:** 2026-06-15
**Context:** DGX Spark GB10 is an ARM64 system with a Blackwell GPU sharing
128GB of unified memory with the host. This differs from x86 multi-GPU nodes:
(a) standard PyPI torch wheels do not target ARM64 cu128 — manual wheel install
required; (b) nvidia-smi VRAM tracking is unreliable on GB10 unified memory —
a custom `monitor_memory.py` is needed; (c) 128GB unified means ctx=128k at
conc=64 may OOM even on a 120B MXFP4 model.
**Decision:** All setup scripts target ARM64 cu128 explicitly. `nvidia-smi` is
never used for memory measurement. `monitor_memory.py` is the sole memory
source. OOM scenarios are logged, not skipped.
**Status:** Accepted.

---

### Decision 4 — Steps 1–2 (HF baseline) are shared across engine comparisons
**Date:** 2026-06-15
**Context:** The vanilla HF baseline (unfused and fused) does not depend on
which inference engine is being compared. Running it once and reusing the numbers
avoids re-loading the 240GB unfused checkpoint multiple times.
**Decision:** Steps 1 and 2 run once. Their CSVs (`hf_unfused.csv`,
`hf_fused.csv`) are inputs to all delta calculations.
**Status:** Accepted.

---

*New decisions appended below as they are made.*
