# Verification

Verification is done with **self-checking SystemVerilog testbenches** and **Python-generated golden vectors**.

The project uses a layered approach:

1. **PE-level correctness** (unit test)
2. **4×4 array correctness** (integration test)
3. **Streaming/top-level correctness** (system test with FIFOs + memh vectors)

---

## What “PASS” means

A test is considered correct when the testbench compares hardware outputs against a known-good reference and prints a PASS message (or completes without mismatch assertions).

---

## Testbenches

Location: `tb/`

### 1) PE unit test
- `tb/tb_pe.sv`
- Focus: signed INT8 multiply, accumulate behavior, reset/en behavior, forwarding registers.

### 2) Array integration tests
- `tb/tb_sa2x2.sv`
- `tb/tb_sa4x4.sv` / `tb/tb_sa4x4_flat.sv` / `tb/tb_sa4x4_pytorch.sv` (depending on what you keep)

Purpose:
- Validate systolic forwarding (A shifts right, B shifts down)
- Validate that each PE accumulates the correct dot-product

Recommended “main” one to keep as your headline:
- `tb/tb_sa4x4_pytorch.sv` (because it’s a clear golden reference story)

### 3) Streaming/top-level test
- `tb/tb_top_memh.sv`

Purpose:
- Validates realistic data ingestion:
  - loads `data/stream_a.memh`, `data/stream_b.memh`
  - compares produced outputs against `data/exp_c.memh`
- Exercises FIFOs + controller + array together

---

## Golden vector generation (Python)

Location: `py/`

Python scripts generate:
- human-readable vectors (`data/vectors.txt`, `data/stream_vectors.txt`)
- synthesizer/testbench-friendly memories (`data/stream_a.memh`, `data/stream_b.memh`, `data/exp_c.memh`)

The golden model performs:
- exact INT8 signed arithmetic for A/B
- accumulation into ACC_W (default 32-bit)

---

## Running simulation 

### Array test (example)
```
iverilog -g2012 -o sim/tb_sa4x4.out rtl/pe.sv rtl/sa4x4.sv tb/tb_sa4x4_pytorch.sv
vvp sim/tb_sa4x4.out
```

### Top streaming test (example)
```
iverilog -g2012 -o sim/tb_top_memh.out \
  rtl/fifo.sv rtl/controller.sv rtl/pe.sv rtl/sa4x4.sv rtl/top.sv \
  tb/tb_top_memh.sv
vvp sim/tb_top_memh.out
```
Waveforms (GTKWave) can be dumped by the testbench to debug mismatches.

---

## Synthesis sanity checks (rough area)
Yosys synthesis lives in:

- synth/yosys.ys
- output netlist: synth/netlist/sa4x4_mapped.v
- report: synth/reports/area.rpt

The area report is a rough proxy using mapped gate counts (AND/XOR/FF, etc.).
It is not physical area in µm², but it is useful for comparisons and “scale feel”.

