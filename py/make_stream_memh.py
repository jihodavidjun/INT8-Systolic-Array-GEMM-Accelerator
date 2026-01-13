def u8(x): return x & 0xFF

def pack4(x0,x1,x2,x3):
    return (u8(x0)<<0) | (u8(x1)<<8) | (u8(x2)<<16) | (u8(x3)<<24)

def to_u32_twos(x):
    return x & 0xFFFFFFFF

def seek(lines, marker):
    for i,l in enumerate(lines):
        if l.strip() == marker:
            return i
    raise RuntimeError(f"missing {marker}")

def main():
    lines = open("vectors.txt").read().splitlines()

    inj = seek(lines, "INJECT:")
    c   = seek(lines, "C:")

    a_words = []
    b_words = []
    for t in range(12):
        a0,a1,a2,a3,b0,b1,b2,b3 = map(int, lines[inj+1+t].split())
        a_words.append(pack4(a0,a1,a2,a3))
        b_words.append(pack4(b0,b1,b2,b3))

    Cvals = []
    for r in range(4):
        Cvals += list(map(int, lines[c+1+r].split()))
    assert len(Cvals) == 16

    with open("stream_a.memh","w") as fa:
        for w in a_words: fa.write(f"{w:08x}\n")

    with open("stream_b.memh","w") as fb:
        for w in b_words: fb.write(f"{w:08x}\n")

    with open("exp_c.memh","w") as fc:
        for x in Cvals:
            fc.write(f"{to_u32_twos(x):08x}\n")

    print("Wrote stream_a.memh (12), stream_b.memh (12), exp_c.memh (16).")

if __name__=="__main__":
    main()
