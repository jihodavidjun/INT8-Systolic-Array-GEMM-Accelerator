# INT8-Systolic-Array-GEMM-Accelerator

This project implements a **signed INT8 systolic array accelerator** for matrix multiplication (GEMM), the core compute primitive behind modern neural network inference accelerators (TPUs, NPUs, AI ASICs).

The design is written in **SystemVerilog**, verified hierarchically from a single processing element (PE) up to a **FIFO-fed top-level accelerator**, and cross-validated against a **PyTorch golden model**.

---

## What This Accelerator Does

- Performs matrix multiplication using a **2D systolic array**
- Each Processing Element (PE) executes a **signed INT8 multiply–accumulate (MAC)**
- Data streams through the array in a **pipelined, steady-state fashion**
- Supports **FIFO-based input streaming** at the top level
- Produces outputs that match **PyTorch `A @ B` exactly** for a 4×4 matrix

This models the compute core used in real ML accelerators such as Google TPUs and inference NPUs.

---

## Why INT8?

INT8 arithmetic is standard for inference because it:

- Reduces **area and power** vs FP32
- Increases **throughput**
- Preserves accuracy with proper quantization

This design uses **signed INT8 inputs** with a **32-bit accumulator** to avoid overflow.

---

## Systolic Dataflow Overview

- **A values flow left → right**
- **B values flow top → bottom**
- **Partial sums remain local** inside each PE
- No global accumulation or shared memory during compute

This minimizes memory traffic and maximizes data reuse.

Detailed diagrams are provided in:
`docs/dataflow.md`

---

## Verification Strategy 

Verification is performed **hierarchically**:

**1. Single PE verification**

**2. 2×2 systolic array verification**

**3. 4×4 systolic array verification**

**4. FIFO-fed top-level verification**

A PyTorch golden model generates reference outputs:

- Random signed INT8 matrices `A` and `B`
- Golden result `C = A @ B`
- RTL results compared element-by-element

Simulation prints:
`PASS: RTL matches PyTorch golden model`
only if all outputs match exactly.

Details are documented in:
`docs/verification.md`

---

## Repository Structure

```
INT8-Systolic-Array-GEMM-Accelerator/
├── rtl/                   # Hardware RTL (SystemVerilog)
│   ├── pe.sv              # Processing Element (INT8 MAC)
│   ├── sa2x2.sv           # 2×2 systolic array
│   ├── sa4x4.sv           # 4×4 systolic array (validated)
│   ├── saNxN.sv           # Parametric NxN version (conceptual)
│   ├── fifo.sv            # Input FIFOs
│   ├── controller.sv      # Stream control logic
│   └── top.sv             # FIFO-fed top-level accelerator
│
├── tb/                    # Testbenches
│   ├── tb_pe.sv
│   ├── tb_sa2x2.sv
│   ├── tb_sa4x4_pytorch.sv
│   ├── tb_top_memh.sv     # Top-level streaming testbench
│   └── legacy/            # Intermediate / exploratory testbenches
│
├── sim/                   # Simulation artifacts
│   ├── *.vcd
│   └── *.gtkw
│
├── py/                    # Python reference model & generators
│   ├── gen_vectors.py
│   ├── gen_stream_vectors.py
│   ├── make_stream_memh.py
│   └── make_stream_vectors.py
│
├── data/                  # Generated test vectors
│   ├── vectors.txt
│   ├── stream_vectors.txt
│   ├── stream_a.memh
│   ├── stream_b.memh
│   └── exp_c.memh
│
├── synth/                 # Synthesis (rough area estimation)
│   ├── yosys.ys
│   ├── netlist/
│   │   └── sa4x4_mapped.v
│   └── reports/
│       ├── area.rpt
│       └── yosys.log
│
├── docs/
│   ├── architecture.md
│   ├── dataflow.md
│   └── verification.md
│
└── README.md
```

---

## Synthesis Results 
The 4×4 systolic array was synthesized using **Yosys** for rough area estimation.

- **Scope**: compute array only (sa4x4)
- **Technology**: generic logic mapping
- **Result**: **~11.8k** total logic cells, **768** flip-flops

These numbers are **not PDK-specific** and are intended for **architectural comparison**, not tape-out.

---

## Tools Used

### Hardware Design & Verification
- **SystemVerilog** (RTL design)
- **Icarus Verilog** (simulation)
- **GTKWave** (waveform inspection)

### Machine Learning Reference
- **Python**
- **PyTorch** (golden reference model)

### Synthesis
- **Yosys** (RTL synthesis and area estimation)
- **ABC** (logic mapping)

---

## Future Work
- STA with PDK, AXI interface, larger arrays

---

## Why This Project Matters

This project demonstrates:

- Hardware dataflow design for ML
- RTL-level verification discipline
- Integration of **Python ML models with hardware verification**
- Realistic accelerator architecture decisions
