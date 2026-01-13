# Systolic Array Architecture

This document explains the internal architecture and dataflow of the INT8 systolic array accelerator implemented in this repository.

---

## Processing Element (PE)

The **Processing Element (PE)** is the fundamental building block.

Each PE contains:
- A signed INT8 × INT8 multiplier
- A wide accumulator register (default 32-bit)
- Pipeline registers for forwarding inputs

### PE Operation (per clock cycle)

If `en == 1`:
1. Multiply `a_in × b_in`
2. Add result to local accumulator
3. Forward:
   - `a_out` → right neighbor
   - `b_out` → bottom neighbor

If `reset == 1`:
- Clear accumulator
- Clear forwarded outputs

The accumulator is **local** to each PE.

---

## Dataflow in the Systolic Array

The array uses **weight-stationary–style systolic dataflow**:

- **A matrix elements (`a`) flow horizontally**
- **B matrix elements (`b`) flow vertically**
- **Partial sums remain local**

### Conceptual Flow (4×4)
```
      b00  b01  b02   b03
       ↓   ↓    ↓     ↓
a00 → PE → PE → PE → PE
       ↓   ↓    ↓     ↓
a10 → PE → PE → PE → PE
       ↓   ↓    ↓     ↓
a20 → PE → PE → PE → PE
       ↓   ↓    ↓     ↓
a30 → PE → PE → PE → PE
```

Each PE computes one output element `C[i][j]`.

---

## Timing and Pipeline Behavior

The systolic array is **pipelined**:

- Inputs are injected over multiple cycles
- Partial sums accumulate over time
- Outputs become valid only after the pipeline fills

This explains why:
- `product` updates appear before `acc_out`
- Output values stabilize several cycles after input injection

This behavior is expected and correct.

---

## 2×2 vs 4×4 vs NxN

- **2×2 (`sa2x2.sv`)**
  - Used for early bring-up and debugging
  - Easy to reason about waveforms

- **4×4 (`sa4x4.sv`)**
  - Main verified compute core
  - Used for PyTorch comparison
  - Represents a realistic accelerator tile

- **NxN (`saNxN.sv`)**
  - Parameterized generator
  - Useful for future scaling and exploration
  - Not required for correctness proof

---

## Verification Philosophy

Verification is **mathematical**, not ad-hoc.

Instead of checking internal signals:
- The array is treated as a black box
- Inputs and outputs are compared to PyTorch GEMM results

If RTL output matches PyTorch:
- The architecture is functionally correct

This mirrors real accelerator verification workflows.

---

## Design Freeze

The following files are considered **frozen compute logic**:

- `pe.sv`
- `sa4x4.sv`

Future work should build **around** these blocks without modifying their internal math.

---

## Summary

This architecture demonstrates:
- Efficient data reuse
- Local accumulation
- Scalable systolic design
- Correct INT8 matrix multiplication

It forms a solid foundation for adding:
- FIFOs / SRAM
- AXI interfaces
- Performance modeling
- Synthesis and timing analysis

