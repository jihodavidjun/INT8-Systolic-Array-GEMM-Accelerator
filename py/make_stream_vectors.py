#!/usr/bin/env python3

def u8(x): return x & 0xFF

def pack4(x0,x1,x2,x3):
    return (u8(x0)<<0) | (u8(x1)<<8) | (u8(x2)<<16) | (u8(x3)<<24)

def seek(lines, marker):
    for i,l in enumerate(lines):
        if l.strip() == marker:
            return i
    raise RuntimeError(f"missing {marker}")

def main():
    lines = open("vectors.txt").read().splitlines()

    inj = seek(lines, "INJECT:")
    c   = seek(lines, "C:")

    # 12 inject cycles
    out = []
    for t in range(12):
        a0,a1,a2,a3,b0,b1,b2,b3 = map(int, lines[inj+1+t].split())
        out.append(f"{pack4(a0,a1,a2,a3):08x} {pack4(b0,b1,b2,b3):08x}")

    # 4 rows of C = 16 ints
    Cvals = []
    for r in range(4):
        Cvals += list(map(int, lines[c+1+r].split()))
    assert len(Cvals)==16

    out += [str(x) for x in Cvals]
    open("stream_vectors.txt","w").write("\n".join(out)+"\n")
    print("Wrote stream_vectors.txt (12 feed + 16 C ints).")

if __name__=="__main__":
    main()
