import os
import sys
import platform
import shutil
import subprocess
from pathlib import Path

RESULTS_DIR = Path(__file__).parent.parent / "results"


def _nvcc_version():
    try:
        out = subprocess.run(
            ["nvcc", "--version"],
            capture_output=True, text=True, timeout=10
        )
        line = next(
            (l.strip() for l in out.stdout.splitlines() if "release" in l.lower()),
            out.stdout.strip() or out.stderr.strip() or "nvcc not found"
        )
        return line
    except FileNotFoundError:
        return "nvcc not found"
    except Exception as e:
        return f"error: {e}"


def _torch_info():
    try:
        import torch
        cuda_ver = torch.version.cuda or "None"
        available = torch.cuda.is_available()
        if available:
            cap = torch.cuda.get_device_capability(0)
            sm = f"sm_{cap[0]}{cap[1]}"
            name = torch.cuda.get_device_name(0)
        else:
            sm = "N/A"
            name = "N/A"
        return cuda_ver, str(available), sm, name
    except ImportError:
        return "torch not installed", "False", "N/A", "N/A"
    except Exception as e:
        return f"error: {e}", "False", "N/A", "N/A"


def _meminfo():
    fields = {"MemTotal": "N/A", "MemAvailable": "N/A", "MemFree": "N/A"}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                key, _, val = line.partition(":")
                if key in fields:
                    kb = int(val.strip().split()[0])
                    fields[key] = f"{kb / 1024 / 1024:.1f} GB"
    except Exception:
        pass
    return fields


def _disk():
    try:
        usage = shutil.disk_usage("/")
        gb = 1024 ** 3
        return {
            "total": f"{usage.total / gb:.1f} GB",
            "used":  f"{usage.used  / gb:.1f} GB",
            "free":  f"{usage.free  / gb:.1f} GB",
        }
    except Exception as e:
        return {"total": f"error: {e}", "used": "N/A", "free": "N/A"}


def build_report():
    u = platform.uname()
    torch_cuda, torch_available, sm_arch, gpu_name = _torch_info()
    mem = _meminfo()
    disk = _disk()

    rows = [
        ("platform.arch",      u.machine),
        ("platform.os",        f"{u.system} {u.release}"),
        ("python.version",     sys.version.split()[0]),
        ("nvcc.version",       _nvcc_version()),
        ("torch.cuda_version", torch_cuda),
        ("torch.cuda_available", torch_available),
        ("gpu.sm_arch",        sm_arch),
        ("gpu.name",           gpu_name),
        ("mem.total",          mem["MemTotal"]),
        ("mem.available",      mem["MemAvailable"]),
        ("mem.free",           mem["MemFree"]),
        ("disk.total",         disk["total"]),
        ("disk.used",          disk["used"]),
        ("disk.free",          disk["free"]),
    ]
    return rows


def main():
    rows = build_report()
    width = max(len(k) for k, _ in rows)
    lines = [f"{k:<{width}} = {v}" for k, v in rows]
    output = "\n".join(lines)

    print(output)

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    report_path = RESULTS_DIR / "env_report.txt"
    report_path.write_text(output + "\n")
    print(f"\nReport written to {report_path}")
    sys.exit(0)


if __name__ == "__main__":
    main()
