# py/gen_vectors.py
import torch
import random
from pathlib import Path

def main():
    torch.manual_seed(0)
    random.seed(0)

    N = 4

    A = torch.randint(low=-8, high=8, size=(N, N), dtype=torch.int32)
    B = torch.randint(low=-8, high=8, size=(N, N), dtype=torch.int32)
    C = A @ B  # int32 matmul
    T = 12

    lines = []
    lines.append("# Format:")
    lines.append("# A matrix (4x4), then B matrix (4x4), then C_ref (4x4)")
    lines.append("# Then T lines of injections: a0 a1 a2 a3 b0 b1 b2 b3")

    lines.append("A:")
    for i in range(N):
        lines.append(" ".join(str(int(A[i, j].item())) for j in range(N)))

    lines.append("B:")
    for i in range(N):
        lines.append(" ".join(str(int(B[i, j].item())) for j in range(N)))

    lines.append("C:")
    for i in range(N):
        lines.append(" ".join(str(int(C[i, j].item())) for j in range(N)))

    lines.append("INJECT:")
    for t in range(T):
        a_vals = []
        b_vals = []
        for i in range(N):
            k = t - i
            a_vals.append(int(A[i, k].item()) if (0 <= k < N) else 0)
        for j in range(N):
            k = t - j
            b_vals.append(int(B[k, j].item()) if (0 <= k < N) else 0)

        lines.append(" ".join(map(str, a_vals + b_vals)))

    out = Path("vectors.txt")
    out.write_text("\n".join(lines) + "\n")
    print("Wrote vectors.txt")
    print("A=\n", A)
    print("B=\n", B)
    print("C=\n", C)

if __name__ == "__main__":
    main()
