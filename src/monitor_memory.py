import argparse, csv, signal, sys, time
from pathlib import Path


def parse_meminfo(text):
    fields = {}
    for line in text.splitlines():
        k, _, v = line.partition(":")
        if k in ("MemTotal", "MemAvailable"):
            fields[k] = int(v.strip().split()[0])
    total = fields["MemTotal"] / 1024 ** 2
    avail = fields["MemAvailable"] / 1024 ** 2
    return total, avail, total - avail


def _snapshot():
    total, avail, used = parse_meminfo(Path("/proc/meminfo").read_text())
    return time.strftime("%Y-%m-%dT%H:%M:%S"), round(total, 2), round(used, 2), round(avail, 2)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--interval", type=float, default=2.0)
    p.add_argument("--output", default="results/memory_log.csv")
    p.add_argument("--once", action="store_true")
    args = p.parse_args()

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    if args.once:
        print(",".join(str(x) for x in _snapshot()))
        sys.exit(0)

    peak_used = 0.0
    start = time.monotonic()

    def shutdown(signum=None, frame=None):
        print(f"peak_used_gb={peak_used:.1f} duration_s={time.monotonic() - start:.1f}")
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)

    with open(out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["timestamp", "mem_total_gb", "mem_used_gb", "mem_available_gb"])
        try:
            while True:
                ts, total, used, avail = _snapshot()
                peak_used = max(peak_used, used)
                row = [ts, total, used, avail]
                w.writerow(row)
                f.flush()
                print(",".join(str(x) for x in row))
                time.sleep(args.interval)
        except KeyboardInterrupt:
            shutdown()


if __name__ == "__main__":
    main()


if __name__ == "__test__":
    def test_parse_meminfo():
        # 131072000 kB = 125.0 GB total; 98304000 kB = 93.75 GB available; used = 31.25 GB
        mock = "MemTotal:  131072000 kB\nMemFree:  65536000 kB\nMemAvailable:  98304000 kB\n"
        total, avail, used = parse_meminfo(mock)
        assert abs(total - 125.0) < 0.01, f"total={total}"
        assert abs(avail - 93.75) < 0.01, f"avail={avail}"
        assert abs(used - 31.25) < 0.01, f"used={used}"
        print("test_parse_meminfo PASS")
    test_parse_meminfo()
