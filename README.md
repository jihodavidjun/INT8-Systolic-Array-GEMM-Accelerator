# INT8 Systolic Array GEMM Accelerator

## 1. Overview
This repository implements a signed INT8 GEMM accelerator in SystemVerilog using a 4x4 systolic array core.

Current implementation includes:
- 4x4 compute core (`rtl/sa4x4.sv`) built from INT8 MAC processing elements (`rtl/pe.sv`)
- Parameterized array module (`rtl/saNxN.sv`) for scaling experiments
- Streaming top-level with dual input FIFOs + controller (`rtl/top.sv`, `rtl/fifo.sv`, `rtl/controller.sv`)
- Hierarchical verification with SystemVerilog testbenches and Python-generated golden data
- Bandwidth-throttled, cycle-accurate performance characterization (`tb/tb_top_bw_perf.sv`, `py/run_bw_sweep.py`)
- Yosys synthesis report for rough logic complexity (`synth/reports/area.rpt`)

The focus is functional correctness and simulation-based performance characterization, not full SoC memory-system modeling.

## 2. Architecture and Dataflow
The compute kernel is a systolic array of PEs:
- Inputs are signed INT8
- Each PE performs INT8xINT8 multiply-accumulate into a 32-bit accumulator
- `A` values propagate horizontally (east)
- `B` values propagate vertically (south)
- Partial sums remain local in each PE accumulator

For the implemented 4x4 core:
- Parallel MAC units: 16
- Peak feed-window compute rate (when fully fed): 16 MAC/cycle

An `NxN` module exists for structural scaling experiments, but repository validation and reported numbers are centered on the 4x4 implementation.

### Example simulation waveform
<img width="1272" height="314" alt="gtksimsysarray" src="https://github.com/user-attachments/assets/d842886f-a949-468a-b31e-fd2c9de84b91" />

## 3. Streaming Top-Level and Control
Top-level pipeline:

`Input streams -> FIFO A/B -> controller -> sa4x4 -> C outputs`

Implemented control behavior:
- Controller starts on `start`
- In FEED state, it issues pops only when both FIFOs are non-empty
- FEED continues until 12 successful word-pair consumptions (`FEED_CYCLES=12`)
- Then FLUSH runs for 4 cycles (`FLUSH_CYCLES=4`) before `done`

Performance counters are implemented in `rtl/controller.sv` and exposed via `rtl/top.sv`:
- `total_feed_cycles`
- `active_feed_cycles`
- `stall_feed_cycles`

Definition used by the performance flow:
- Stall cycle = FEED-state cycle where at least one FIFO is empty, so no A/B word pair is consumed.

## 4. Verification
Verification is layered and self-checking:

1. PE unit test:
- `tb/tb_pe.sv`

2. Array-level tests (including PyTorch reference comparison):
- `tb/tb_sa2x2.sv`
- `tb/tb_sa4x4.sv`
- `tb/tb_sa4x4_flat.sv`
- `tb/tb_sa4x4_pytorch.sv`

3. Streaming top-level correctness:
- `tb/tb_top_memh.sv`
- Uses `data/stream_a.memh`, `data/stream_b.memh`, `data/exp_c.memh`

PyTorch vector/memory generators:
- `py/gen_vectors.py`
- `py/make_stream_memh.py`
- `py/gen_stream_vectors.py`

Typical runs:

```bash
# 4x4 array vs PyTorch-derived vectors
iverilog -g2012 -o sim/tb_sa4x4.out rtl/pe.sv rtl/sa4x4.sv tb/tb_sa4x4_pytorch.sv
vvp sim/tb_sa4x4.out

# Streaming top-level correctness
iverilog -g2012 -o sim/tb_top_memh.out \
  rtl/fifo.sv rtl/controller.sv rtl/pe.sv rtl/sa4x4.sv rtl/top.sv \
  tb/tb_top_memh.sv
vvp sim/tb_top_memh.out
```

## 5. Performance Characterization
### Methodology
Performance characterization is done with `tb/tb_top_bw_perf.sv`.

What it does:
- Streams the same verified workload while intentionally throttling feed rate
- Uses controller counters to measure active vs stall behavior in the FEED window
- Computes utilization and effective throughput from cycle counts
- Optionally appends run results to CSV (`sim/bw_sweep.csv`)

Run commands:

```bash
# Build performance testbench
iverilog -g2012 -o sim/tb_top_bw_perf.out \
  rtl/fifo.sv rtl/controller.sv rtl/pe.sv rtl/sa4x4.sv rtl/top.sv \
  tb/tb_top_bw_perf.sv

# Default 3-case sweep and CSV export
python3 py/run_bw_sweep.py
```

### Parameters (`GAP`, `PRELOAD`)
- `GAP`: idle cycles inserted between pushed A/B word pairs after each successful push
- `PRELOAD`: number of A/B word pairs loaded before asserting `start`

Interpretation:
- Larger `GAP` reduces sustained input feed rate
- Smaller `PRELOAD` reduces startup buffering and can increase early stalls

### Metric definitions
For each case:
- `total_feed_cycles`: cycles spent in FEED state
- `active_feed_cycles`: FEED cycles that consumed one A/B word pair
- `stall_feed_cycles`: FEED cycles with no consume due to FIFO underflow condition

Derived metrics:
- `util_feed (%) = 100 * active_feed_cycles / total_feed_cycles`
- `throughput_feed (MAC/cycle) = (N^2 * K) / total_feed_cycles`
- `throughput_exec (MAC/cycle) = (N^2 * K) / (total_feed_cycles + FLUSH_CYCLES)`
- `macs_per_input_byte = (N^2 * K) / (active_feed_cycles * 8)`

This workload uses `N=4`, `K=12`, so total MACs per run are 192.

### Results tables
Source: validated `PERF_SUMMARY` output and `sim/bw_sweep.csv`.

**Table A: Feed utilization and stalls**

| Case | GAP | PRELOAD | total_feed_cycles | active_feed_cycles | stall_feed_cycles | util_feed (%) |
| --- | --- | --- | --- | --- | --- | --- |
| ideal_full_feed | 0 | 12 | 12 | 12 | 0 | 100.00 |
| reduced_feed_gap1 | 1 | 2 | 21 | 12 | 9 | 57.14 |
| constrained_feed_gap3 | 3 | 0 | 47 | 12 | 35 | 25.53 |

**Table B: Effective throughput and input efficiency**

| Case | throughput_feed (MAC/cycle) | throughput_exec (MAC/cycle) | macs_per_input_byte |
| --- | --- | --- | --- |
| ideal_full_feed | 16.000 | 12.000 | 2.000 |
| reduced_feed_gap1 | 9.143 | 7.680 | 2.000 |
| constrained_feed_gap3 | 4.085 | 3.765 | 2.000 |

### Key observations
- Feed throttling directly reduces utilization: 100.00% -> 57.14% -> 25.53% across the three cases.
- Stall cycles increase as feed is constrained: 0 -> 9 -> 35.
- Effective throughput drops accordingly in both feed-window and execution-window definitions.
- `macs_per_input_byte` stays constant in this setup because total consumed bytes and total MAC count are fixed for this workload.

## 6. Synthesis
Yosys synthesis artifacts are in `synth/`.

From `synth/reports/area.rpt` (4x4 core hierarchy):
- Total mapped cells: 11,840
- Flip-flops (`$_SDFFE_PP0P_`): 768

These are logic-mapped counts from Yosys/ABC, useful for relative complexity; they are not physical area (um^2) or post-layout timing/power.

## 7. Limitations
- Performance numbers are simulation-based under the implemented feed-throttle model.
- No DRAM, AXI, arbitration, cache, or burst-traffic modeling is implemented.
- No post-route timing closure or silicon frequency characterization is included.
- Published performance results are for the current 4x4-centered flow.

## 8. Future Work
- Add a realistic external-memory interface model and transaction-level bandwidth experiments.
- Extend characterization across larger `N` configurations using `saNxN`.
- Add automated regression scripts that combine correctness and performance sweeps.
- Add FPGA prototyping and timing-aware implementation studies.
