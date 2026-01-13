# INT8 Systolic Array Accelerator for Neural Network Inference

This project implements a **signed INT8 systolic array accelerator** for matrix multiplication, a core operation in modern neural network inference.

The design is written in **SystemVerilog**, verified at multiple levels (single PE → 2×2 → 4×4 array), and **cross-validated against a PyTorch golden model** to ensure numerical correctness.

---

## What This Accelerator Does

- Computes matrix multiplication using a **systolic array** of processing elements (PEs)
- Each PE performs a **multiply–accumulate (MAC)** operation on signed INT8 inputs
- Supports **steady-state pipelined operation**
- Produces correct results matching PyTorch `A @ B` for a 4×4 matrix

This models the compute core used in hardware accelerators such as **TPUs, NPUs, and AI inference ASICs**.

---

## Why INT8?

INT8 arithmetic is widely used in **neural network inference** because:

- It drastically reduces **area and power** compared to FP32
- It increases **throughput** and **energy efficiency**
- Most modern models tolerate INT8 quantization with minimal accuracy loss

This project assumes **signed INT8 inputs** and a wider accumulator (default 32-bit) to prevent overflow.

---

## What Is a Systolic Array?

A systolic array is a **regular grid of compute units** where data flows rhythmically through the array:

- **`a` values flow horizontally (left → right)**
- **`b` values flow vertically (top → bottom)**
- **partial sums stay local inside each PE**

This minimizes global memory access and maximizes data reuse, making it ideal for matrix multiplication.

---

## Verification Strategy (RTL vs PyTorch)

Correctness is verified using a **PyTorch-based golden model**:

1. Random matrices `A` and `B` are generated in Python
2. PyTorch computes `C = A @ B`
3. The same inputs are streamed into the RTL systolic array
4. After pipeline latency, RTL outputs are compared element-by-element against PyTorch

The simulation prints:

`PASS: RTL sa4x4 matches PyTorch golden model.`

if — and only if — all outputs match.

---

## Repository Structure

```markdown
systolic_pe/
├── rtl/ # Hardware design (SystemVerilog)
│ ├── pe.sv # Processing Element (MAC)
│ ├── sa2x2.sv # 2×2 systolic array
│ ├── sa4x4.sv # 4×4 systolic array (main compute core)
│ └── saNxN.sv # Parameterized NxN version (exploratory)
│
├── tb/ # Testbenches
│ ├── tb_pe.sv
│ ├── tb_sa2x2.sv
│ ├── tb_sa4x4.sv
│ ├── tb_sa4x4_flat.sv
│ └── tb_sa4x4_pytorch.sv # PyTorch-driven verification
│
├── py/
│ └── gen_vectors.py # PyTorch golden model generator
│
├── docs/
│ └── architecture.md # Detailed architecture explanation
│
└── vectors.txt # Generated test vectors
```

---

## Tools Used

- **SystemVerilog** (RTL design)
- **Icarus Verilog** (simulation)
- **GTKWave** (waveform inspection)
- **PyTorch** (golden reference model)

---

## Why This Project Matters

This project demonstrates:
- Understanding of **hardware dataflow architectures**
- Practical **VLSI + ML co-design**
- Industry-style **verification methodology**
- Ability to scale from **RTL blocks → system-level design**
