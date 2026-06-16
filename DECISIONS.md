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

### Decision 5 — PyTorch CUDA version upgraded cu128 → cu130 by SGLang deps
**Date:** 2026-06-16
**Context:** `scripts/01_install_pytorch_arm64.sh` installed `torch 2.11.0+cu128`
from the cu128 index as planned. When SGLang was subsequently installed, its
dependency resolver pulled a newer torch build (`2.12.0+cu130`), silently
upgrading the CUDA runtime. `torchvision` was not re-installed and remained on
cu128, causing a CUDA version mismatch at import (`torchvision` expects cu128,
runtime is cu130).
**Fix applied:** Reinstalled torchvision from the cu130 index:
```
pip install torchvision --index-url https://download.pytorch.org/whl/cu130
```
**Final confirmed stack on gx10-09d2:**
- torch 2.12.0+cu130
- torchvision 0.27.0+cu130
- sglang 0.5.13.post1
- vllm 0.23.0
**How to apply:** All future install scripts should pin to cu130, not cu128.
`scripts/01_install_pytorch_arm64.sh` is stale — update index URL before reuse.
**Status:** Resolved.

---

### Decision 6 — GB10 SM arch confirmed as SM 12.1 (Blackwell)
**Date:** 2026-06-16
**Context:** `torch.cuda.get_device_capability()` on gx10-09d2 returned `(12, 1)`.
Both vLLM 0.23.0 and SGLang 0.5.13.post1 imported cleanly without SM arch errors,
confirming that stable releases of both engines already include Blackwell support.
No nightly or source build was needed.
**Decision:** Use stable releases for both engines. The nightly fallback paths in
`scripts/02_install_vllm_arm64.sh` and `scripts/03_install_sglang_arm64.sh` are
retained as safety nets but were not exercised.
**Status:** Accepted.

---

### Decision 7 — SGLang install script had copy-paste bug in verification block
**Date:** 2026-06-16
**Context:** `scripts/03_install_sglang_arm64.sh` was written by adapting the
vLLM install script. The verification block was not updated and imported `vllm`
instead of `sglang`, meaning a failed SGLang install would have passed the gate
silently as long as vLLM was present.
**Fix applied:** Corrected manually on the node before running. The script in
the repo still contains the bug and must be patched.
**How to apply:** Fix the verification block in `scripts/03_install_sglang_arm64.sh`
to import `sglang`, not `vllm`. See [[Decision 6]] — both imports now confirmed
working, so the fix is cosmetic but required for correctness.
**Status:** Noted; script fix pending.

---

### Decision 8 — venv canonical location is ~/venv
**Date:** 2026-06-16
**Context:** All packages installed into `~/venv` on gx10-09d2.
**Decision:** Every benchmark script and install script must begin with a
`$VIRTUAL_ENV` check (already present in Phase 3–4 scripts). The correct
activation command is `source ~/venv/bin/activate`.
**Status:** Accepted.

---

*New decisions appended below as they are made.*
