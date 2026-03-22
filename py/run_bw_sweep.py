import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SIM_DIR = ROOT / "sim"
TB_OUT = SIM_DIR / "tb_top_bw_perf.out"
CSV_OUT = SIM_DIR / "bw_sweep.csv"


def run(cmd, cwd=ROOT):
    p = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if p.returncode != 0:
        print(p.stdout, end="")
        print(p.stderr, end="")
        raise SystemExit(p.returncode)
    return p.stdout


def main():
    SIM_DIR.mkdir(exist_ok=True)

    compile_cmd = [
        "iverilog",
        "-g2012",
        "-o",
        str(TB_OUT),
        "rtl/fifo.sv",
        "rtl/controller.sv",
        "rtl/pe.sv",
        "rtl/sa4x4.sv",
        "rtl/top.sv",
        "tb/tb_top_bw_perf.sv",
    ]
    run(compile_cmd)

    header = (
        "case,gap,preload,feed_total,active,stall,util_feed_pct,stall_pct,"
        "macs,tput_feed_mac_per_cycle,tput_exec_mac_per_cycle,in_bytes,"
        "macs_per_input_byte,reuse_a,reuse_b\n"
    )
    CSV_OUT.write_text(header)

    cases = [
        ("ideal_full_feed", 0, 12),
        ("reduced_feed_gap1", 1, 2),
        ("constrained_feed_gap3", 3, 0),
    ]

    for case_name, gap, preload in cases:
        run_cmd = [
            "vvp",
            str(TB_OUT),
            f"+CASE={case_name}",
            f"+GAP={gap}",
            f"+PRELOAD={preload}",
            f"+PERF_CSV={CSV_OUT}",
        ]
        out = run(run_cmd)
        summary = ""
        for line in out.splitlines():
            if line.startswith("PERF_SUMMARY"):
                summary = line
                break
        if summary:
            print(summary)
        else:
            print(f"[warn] No PERF_SUMMARY line found for case={case_name}")

    print(f"Wrote {CSV_OUT}")


if __name__ == "__main__":
    main()
