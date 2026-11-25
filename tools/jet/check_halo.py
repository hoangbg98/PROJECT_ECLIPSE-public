"""Do quang den ngả xanh quanh vat the trong anh nen Bay Nguyen To (loi nen key xanh la con sot).
Dung: python -X utf8 tools/jet/check_halo.py <anh.png> [<anh2.png> ...]
Moi anh: dem pixel dac (alpha >= 200) toi (do sang 8-38) va ngả xanh la (G >= R+3, G >= B+3) nam trong 16 px tinh tu vung trong suot
(alpha < 8), chia cho so pixel dac cung dai do. Anh nen sach (ash, wind): ~0.1%. Nguong de xuat: <= 1%.
Can numpy + Pillow (Python 3.12 cua may build co san)."""
import sys

import numpy as np
from PIL import Image


def dilate(mask, n):
    out = mask.copy()
    for _ in range(n):
        p = np.pad(out, 1)
        out = p[1:-1, 1:-1] | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return out


def halo(path, reach=16):
    a = np.array(Image.open(path).convert('RGBA')).astype(int)
    r, g, b, al = [a[..., i] for i in range(4)]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    clear = al < 8
    near = dilate(clear, reach) & ~clear
    cand = (al >= 200) & (lum >= 8) & (lum <= 38) & (g >= r + 3) & (g >= b + 3)
    n = int((cand & near).sum())
    d = int((near & (al >= 200)).sum())
    return n, d


if __name__ == '__main__':
    bad = 0
    for f in sys.argv[1:]:
        n, d = halo(f)
        pct = 100.0 * n / max(d, 1)
        ok = pct <= 1.0
        bad += 0 if ok else 1
        print('%-40s quang %7d / %8d px dac gan mep = %5.1f%%  %s' % (f, n, d, pct, 'DAT' if ok else 'LOI'))
    sys.exit(1 if bad else 0)
