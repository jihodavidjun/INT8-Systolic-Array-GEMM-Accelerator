# INT8-Systolic-Array-GEMM-Accelerator

This repository implements a **signed INT8 systolic array accelerator** for matrix multiplication (GEMM), the compute primitive behind modern ML inference accelerators such as TPUs and NPUs. The design is written in **SystemVerilog** and verified hierarchically (from a single processing element to a top-level streaming accelerator) against a **PyTorch golden model**.

---

## High-level pipeline

Overall data path through the accelerator:

Input A/B → FIFOs → Stream Controller → Systolic Array (NxN PEs) → Output C

The system accepts streams of **A** and **B** input matrices, buffers them in FIFOs, orchestrates timing via a controller and performs multiply–accumulate using a 2D systolic array. The result stream produces the matrix **C**.

---

## Systolic Dataflow

Each **Processing Element (PE)** contains an INT8×INT8 multiplier and a local accumulator. **A** values flow east across the array; **B** values flow south; partial sums remain local. The following diagram illustrates the 4×4 case:

An **NxN** parameterized version (`rtl/saNxN.sv`) is provided for scaling beyond 4×4.

---

## Why INT8?

INT8 arithmetic reduces area and power consumption compared to floating point and increases throughput while maintaining accuracy when combined with proper quantization. The design uses signed INT8 inputs with a 32-bit accumulator to avoid overflow.

---

## Verification Strategy 

Verification is performed hierarchically using self-checking **SystemVerilog testbenches** and **Python scripts** to generate golden data:

1. **PE-level tests** (`tb/tb_pe.sv`) validate signed INT8 multiply-accumulate behavior, reset handling, and operand forwarding within a single processing element.

2. **Array-level tests** (`tb/tb_sa4x4_pytorch.sv`) feed randomly generated INT8 matrices and compare the RTL output against PyTorch’s `A @ B` result.

3. **Top-level streaming tests** (`tb/tb_top_memh.sv`) exercise the full accelerator pipeline including FIFOs, the controller, and the **systolic array by streaming `.memh` input files.

The Python scripts in `py/` generate human-readable vector files and `.memh` memory images for both inputs and expected outputs.

### Example simulation waveform

<img width="1272" height="314" alt="gtksimsysarray" src="https://github.com/user-attachments/assets/d842886f-a949-468a-b31e-fd2c9de84b91" />

The waveform shows the systolic accumulation behavior where each PE performs an INT8×INT8 multiply-accumulate while forwarding operands to neighboring processing elements.

---

## Quick Start

To run the 4×4 array test with Icarus Verilog:
```
iverilog -g2012 -o sim/tb_sa4x4.out rtl/pe.sv rtl/sa4x4.sv tb/tb_sa4x4_pytorch.sv
vvp sim/tb_sa4x4.out
```
For the top-level streaming test:
```
iverilog -g2012 -o sim/tb_top_memh.out \
  rtl/fifo.sv rtl/controller.sv rtl/pe.sv rtl/sa4x4.sv rtl/top.sv \
  tb/tb_top_memh.sv
vvp sim/tb_top_memh.out
```
A **PASS** message indicates the RTL matches the golden model.

---

## Repository Structure
```
rtl/       # SystemVerilog RTL: PE, 2×2/4×4/NxN arrays, FIFOs, controller, top
tb/        # Testbenches: PE, 2×2 array, 4×4 array, streaming top
py/        # Python scripts: generate vectors, stream memh files, reference model
data/      # Generated test vectors and memh files
sim/       # Simulation artifacts: compiled testbench binaries, VCD waveform dumps, GTKWave viewing
synth/     # Yosys synthesis scripts, netlists, area reports
docs/      # Additional documentation (architecture, dataflow, verification)
```

---

## Synthesis & Performance
The 4×4 array was synthesized using **Yosys** for rough area estimation:

| Scope | Technology                  | Approx. logic cells | Flip-flops |
| ----- | --------------------------- | ------------------- | ---------- |
| sa4x4 | generic logic mapping (ABC) | ~11.8k              | 768        |

### Performance Model

For an **N×N systolic array**:

- Number of MAC units: **N²**
- Peak throughput: **N² MACs per cycle**

Example:

| Array size | MAC units | Peak throughput |
|-----------|-----------|----------------|
| 4×4 | 16 | 16 MACs / cycle |
| 8×8 | 64 | 64 MACs / cycle |

### Latency

For matrix multiplication C = A × B, where A = N × K and B = K × N, the compute phase requires **K cycles**, while the systolic pipeline introduces additional fill and drain latency.

- Approximate latency: Latency ≈ K + 2(N − 1)
- For the implemented **4×4 array**: Latency ≈ K + 6 cycles

This model reflects the time required for data to propagate across the array and for partial sums to flush from the pipeline.

---

## Future Work
- Extend timing analysis using a real PDK.
- Add interfaces (AXI/AHB) and memory-mapped registers.
- Synthesize and test larger arrays (e.g. 8×8) to measure scaling.
- Optional FPGA prototype for demonstration.
